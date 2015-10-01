module RoRmaily
  class Mailing < Dispatch
    include RoRmaily::TemplateRenderer
    include RoRmaily::Autonaming

    if Rails::VERSION::MAJOR == 3
      attr_accessible :name, :title, :subject, :context_name, :override_subscription,
                      :sequence, :conditions, :mailer_name, :title, :from, :relative_delay, :template, :start_at, :period
    end

    has_many    :logs,          class_name: "RoRmaily::Log"
    
    validates   :subject,       presence: true, if: :generic_mailer?
    validates   :template,      presence: true, if: :generic_mailer?
    validate    :template_syntax
    validate    :validate_conditions

    before_validation do
      write_attribute(:name, self.title.downcase.gsub(/\W/, "_")) if self.title && (!self.name || self.name.empty?)
    end

    after_initialize do
      if self.new_record?
        self.override_subscription = false
        self.mailer_name = :generic
      end

      if @conditions_proc
        self.conditions = "proc"
      end
    end

    after_save do
      if @conditions_proc
        @@conditions_procs[self.id] = @conditions_proc
      end
    end

    @@conditions_procs = {}

    def conditions= v
      if v.respond_to? :call
        @conditions_proc = v
      else
        write_attribute(:conditions, v)
      end
    end

    def conditions
      @conditions_proc || @@conditions_procs[self.id] || read_attribute(:conditions)
    end

    def has_conditions_proc?
      @conditions_proc || @@conditions_procs[self.id]
    end

    def conditions_changed?
      if has_conditions_proc?
        @conditions_proc != @@conditions_procs[self.id]
      else
        super
      end
    end

    def periodical?
      self.class == PeriodicalMailing
    end

    def one_time?
      self.class == OneTimeMailing
    end

    def sequence?
      self.class == SequenceMailing
    end

    def mailer_name
      read_attribute(:mailer_name).to_sym
    end

    # Returns {Mailer} class used by this Mailing.
    def mailer
      if generic_mailer?
        RoRmaily::Mailer
      else
        self.mailer_name.to_s.constantize
      end
    end

    # Checks whether Mailing uses generic mailer.
    def generic_mailer?
      self.mailer_name == :generic
    end

    # Checks whether Mailig has conditions defined.
    def has_conditions?
      self.conditions && (has_conditions_proc? || !self.conditions.empty?)
    end

    # Checks whether entity meets conditions of this Mailing.
    #
    # @raise [ArgumentError] if the conditions do not evaluate to boolean.
    def conditions_met? entity
      subscription = self.list.subscription_for(entity)

      if has_conditions_proc?
        !!conditions.call(entity, subscription)
      else
        if self.list.context.attributes
          evaluator = Utils::MarkupEvaluator.new(self.list.context.drop_for(entity, subscription))
          evaluator.evaluate_conditions(self.conditions)
        else
          true
        end
      end
    end

    # Checks whether conditions evaluate properly for given entity.
    def test_conditions entity
      conditions_met?(entity)
      true
    rescue StandardError => e
      false
    end

    # Returns destination email address for given entity.
    def destination entity
      self.list.context.destination_for(entity)
    end

    # Renders email body for given entity.
    #
    # Reads {#template} attribute and renders it using Liquid within the context
    # for provided entity.
    def render_template entity
      subscription = self.list.subscription_for(entity)
      return unless subscription

      drop = self.list.context.drop_for entity, subscription
      perform_template_rendering drop, self.template
    end

    # Renders email subject line for given entity.
    #
    # Reads {#subject} attribute and renders it using Liquid within the context
    # for provided entity.
    def render_subject entity
      subscription = self.list.subscription_for(entity)
      return unless subscription

      drop = self.list.context.drop_for entity, subscription
      perform_template_rendering drop, self.subject
    end

    # Builds `Mail::Message` object for given entity.
    #
    # Depending on {#mailer_name} value it uses either generic mailer (from {Mailer} class)
    # or custom mailer.
    def build_mail entity
      if generic_mailer?
        Mailer.generic(entity, self)
      else
        self.mailer.send(self.name, entity)
      end
    end

    protected

    # Sends mailing to given entity.
    #
    # Performs actual sending of emails; should be called in background.
    #
    # Returns `Mail::Message`.
    def deliver_to entity
      build_mail(entity).deliver
    end

    # Called from Mailer, block required
    def deliver_with_mailer_to entity
      unless processable?(entity)
        RoRmaily.logger.log_processing(self, entity, prefix: "Not processable", level: :debug) 
        return 
      end

      unless conditions_met?(entity)
        RoRmaily.logger.log_processing(self, entity, prefix: "Conditions not met", level: :debug) 
        return {status: :skipped}
      end

      mail = yield # Let mailer do his job

      RoRmaily.logger.log_processing(self, entity, mail, prefix: "Processed") 

      return {status: :delivered, data: {content: mail.to_s}}
    rescue StandardError => e
      RoRmaily.logger.log_processing(self, entity, prefix: "Error", level: :error) 
      return {status: :error, data: {msg: "#{e.to_s}\n\n#{e.backtrace.join("\n")}"}}
    end

    private

    def template_syntax
      begin
        template = Liquid::Template.parse(self.template)
      rescue StandardError => e
        errors.add(:template, e.to_s)
      end
    end

    def validate_conditions
      return true if has_conditions_proc?

      result = Utils::MarkupEvaluator.test_conditions(self.conditions)

      errors.add(:conditions, "is not a boolean value") unless result
    rescue StandardError => e
      errors.add(:conditions, e.to_s) 
    end

    def validate_start_at
      return true if has_start_at_proc?

      result = Utils::MarkupEvaluator.test_start_at(self.start_at)

      errors.add(:start_at, "is not a time value") unless result
    rescue StandardError => e
      errors.add(:start_at, e.to_s) 
    end
  end
end
