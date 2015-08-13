module RoRmaily
  module ModelExtensions
    def self.included(base)
      unloadable
      base.class_eval do
        has_many    :ror_maily_subscriptions,       as: :entity, class_name: "RoRmaily::Subscription", dependent: :destroy
        has_many    :ror_maily_logs,                as: :entity, class_name: "RoRmaily::Log"

        after_destroy do
          self.ror_maily_logs.scheduled.destroy_all
        end
      end
    end
  end
end
