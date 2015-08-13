module RoRmaily
  class Mailer < ActionMailer::Base
    attr_reader :entity

    def generic entity, mailing
      destination = mailing.destination(entity)
      subject = mailing.render_subject(entity)
      content = mailing.render_template(entity)

      opts = {
        to: destination, 
        subject: subject
      }
      opts[:from] = mailing.from if mailing.from.present?

      mail(opts) do |format|
        format.text { render text: content }
      end
    end

    class << self
      #TODO make it instance method so we get access to instance attributes
      def deliver_mail(mail) #:nodoc:
        mailing = mail.ror_maily_data[:mailing]
        entity = mail.ror_maily_data[:entity]


        if mailing && entity
          mailing.deliver_with_mailer_to(entity) do
            ActiveSupport::Notifications.instrument("deliver.action_mailer") do |payload|
              self.set_payload_for_mail(payload, mail)
              yield # Let Mail do the delivery actions
            end
            mail
          end
        else
          RoRmaily.logger.log_processing(mailing, entity, mail, prefix: "Delivery outside Maily")

          ActiveSupport::Notifications.instrument("deliver.action_mailer") do |payload|
            self.set_payload_for_mail(payload, mail)
            yield # Let Mail do the delivery actions
          end
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

      mailing = args[0].to_s == "generic" ? args[2] : RoRmaily.dispatch(args[0])
      entity = args[1]

      @_message.ror_maily_data = {
        mailing: mailing,
        entity: entity,
        subscription: mailing.subscription_for(entity),
      }

      lookup_context.skip_default_locale!
      super

      @_message.to = mailing.destination(entity) unless @_message.to
      @_message.from = mailing.from unless @_message.from

      @_message
    end
  end
end
