module RoRmaily
  class Mailer < ActionMailer::Base
    attr_reader :entity

    def generic entity
      destination = @ror_maily_mailing.destination(entity)
      subject = @ror_maily_mailing.render_subject(entity)
      content = @ror_maily_mailing.render_template(entity)

      opts = {
        to: destination, 
        subject: subject
      }
      opts[:from] = @ror_maily_mailing.from if @ror_maily_mailing.from.present?

      mail(opts) do |format|
        format.text { render text: content }
      end
    end

    class << self
      #TODO make it instance method so we get access to instance attributes
      def deliver_mail(mail) #:nodoc:
        mailing = mail.ror_maily_data[:mailing]
        entity = mail.ror_maily_data[:entity]
        schedule = mail.ror_maily_data[:schedule]

        if !schedule && mailing.respond_to?(:schedule_delivery_to)
          # Implicitly create schedule for ad hoc delivery when called using Mailer.foo(entity).deliver syntax
          schedule = mail.ror_maily_data[:schedule] = mailing.schedule_delivery_to(entity)
        end

        if schedule
          mailing.send(:deliver_with_mailer, schedule) do
            ActiveSupport::Notifications.instrument("deliver.action_mailer") do |payload|
              self.set_payload_for_mail(payload, mail)
              yield # Let Mail do the delivery actions
            end
            mail
          end
        else
          RoRmaily.logger.log_processing(mailing, entity, mail, prefix: "Attempt to deliver email without schedule. No mail was sent", level: :debug)

          #ActiveSupport::Notifications.instrument("deliver.action_mailer") do |payload|
            #self.set_payload_for_mail(payload, mail)
            #yield # Let Mail do the delivery actions
          #end
        end
      end
    end

    def mail(headers = {}, &block)
      return @_message if @_mail_was_called && headers.blank? && !block

      # Assign instance variables availabe for template
      @maily_subscription = @_message.ror_maily_data[:subscription]
      @maily_entity = @_message.ror_maily_data[:entity]
      @maily_mailing = @_message.ror_maily_data[:mailing]

      super
    end

    protected

    def process(*args) #:nodoc:
      class << @_message
        attr_accessor :ror_maily_data

        def ror_maily_processable?
          @ror_maily_processable ||= ror_maily_data[:mailing].processable?(ror_maily_data[:entity])
        end

        def ror_maily_conditions_met?
          @ror_maily_conditions_met ||= ror_maily_data[:mailing].conditions_met?(ror_maily_data[:entity])
        end
      end

      if args[1].is_a?(RoRmaily::Log)
        @ror_maily_schedule = args[1]
        @ror_maily_mailing = @ror_maily_schedule.mailing
        @ror_maily_entity = @ror_maily_schedule.entity
      else
        @ror_maily_mailing = args[0].to_s == "generic" ? args[2] : RoRmaily.dispatch(args[0])
        @ror_maily_entity = args[1]
      end

      @_message.ror_maily_data = {
        schedule: @ror_maily_schedule,
        mailing: @ror_maily_mailing,
        entity: @ror_maily_entity,
        subscription: @ror_maily_mailing.subscription_for(@ror_maily_entity),
      }

      lookup_context.skip_default_locale!
      super(args[0], @ror_maily_entity)

      @_message.to = @ror_maily_mailing.destination(@ror_maily_entity) unless @_message.to
      @_message.from = @ror_maily_mailing.from unless @_message.from

      @_message
    end
  end
end
