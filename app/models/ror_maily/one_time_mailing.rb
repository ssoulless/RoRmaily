module RoRmaily
  class OneTimeMailing < Mailing
    validates   :list,          presence: true
    validates   :start_at,      presence: true

    after_save :update_schedules_callback, if: Proc.new{|m| m.state_changed? || m.start_at_changed? || m.override_subscription?}

    def deliver_with_mailer_to entity
      current_time = Time.now

      schedule = schedule_for entity

      schedule.with_lock do
        # make sure schedule hasn't been processed in the meantime
        if schedule && schedule.processing_at <= current_time && schedule.scheduled?
          attrs = super(entity)
          if attrs
            schedule.attributes = attrs
            schedule.processing_at = current_time
            schedule.save!
          end
        end
      end if schedule
    end

    # Sends mailing to all subscribed entities.
    #
    # Performs actual sending of emails; should be called in background.
    #
    # Returns array of {MailyHerald::Log} with actual `Mail::Message` objects stored
    # in {MailyHerald::Log.mail} attributes.
    def run
      # TODO better scope here to exclude schedules for users outside context scope
      schedules.where("processing_at <= (?)", Time.now).collect do |schedule|
        if schedule.entity
          mail = deliver_to schedule.entity
          schedule.reload
          schedule.mail = mail
          schedule
        else
          MailyHerald.logger.log_processing(schedule.mailing, {class: schedule.entity_type, id: schedule.entity_id}, prefix: "Removing schedule for non-existing entity") 
          schedule.destroy
        end
      end
    end

    # Returns collection of processed {Log}s for given entity.
    def processed_logs entity
      Log.ordered.for_entity(entity).for_mailing(self).processed
    end

    # Sets the delivery schedule for given entity
    #
    # New schedule will be created or existing one updated.
    # Schedule is {Log} object of type "schedule".
    def set_schedule_for entity
      if processed_logs(entity).last
        # this mailing is sent only once
        log = schedule_for(entity)
        log.try(:destroy)
        return
      end

      # support entity with joined subscription table for better performance
      if entity.has_attribute?(:maily_subscription_id)
        subscribed = !!entity.maily_subscription_active
      else
        subscribed = self.list.subscribed?(entity)
      end

      if !self.start_at || !enabled? || !(self.override_subscription? || subscribed)
        log = schedule_for(entity)
        log.try(:destroy)
        return
      end

      log = schedule_for(entity)

      log ||= Log.new
      log.with_lock do
        log.set_attributes_for(self, entity, {
          status: :scheduled,
          processing_at: start_processing_time(entity)
        })
        log.save!
      end
      log
    end

    # Sets delivery schedules of all entities in mailing scope.
    #
    # New schedules will be created or existing ones updated.
    def set_schedules
      self.list.context.scope_with_subscription(self.list, :outer).each do |entity|
        MailyHerald.logger.debug "Updating schedule of #{self} one-time for entity ##{entity.id} #{entity}"
        set_schedule_for entity
      end
    end

    def update_schedules_callback
      Rails.env.test? ? set_schedules : MailyHerald::ScheduleUpdater.perform_in(10.seconds, self.id)
    end

    # Returns {Log} object which is the delivery schedule for given entity.
    def schedule_for entity
      schedules.for_entity(entity).first
    end

    # Returns collection of all delivery schedules ({Log} collection).
    def schedules
      Log.ordered.scheduled.for_mailing(self)
    end

    # Returns processing time for given entity.
    #
    # This is the time when next mailing should be sent based on
    # {#start_at} mailing attribute.
    def start_processing_time entity
      begin
        Time.parse(self.start_at)
      rescue
        subscription = self.list.subscription_for(entity)
        evaluator = Utils::MarkupEvaluator.new(self.list.context.drop_for(entity, subscription))

        evaluator.evaluate_variable(self.start_at)
      end
    end

    def to_s
      "<OneTimeMailing: #{self.title || self.name}>"
    end
  end
end
