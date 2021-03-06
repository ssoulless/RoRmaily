module RoRmaily
  # Stores information about email delivery to entity.
  #
  # It is associated with entity object and {Dispatch}.
  # Log can have following statuses:
  # - +scheduled+ - email hasn't been processed yet,
  # - +delivered+ - email was sent to entity,
  # - +skipped+ - email deliver was skipped (i.e. due to conditions not met),
  # - +error+ - there was an error during email delivery.
  #
  # @attr [Fixnum]    entity_id      Entity association id.
  # @attr [String]    entity_type    Entity association type.
  # @attr [String]    entity_email   Delivery email. Stored in case associated entity gets deleted.
  # @attr [Fixnum]    mailing_id     {Dispatch} association id.
  # @attr [Sumbol]    status         
  # @attr [Hash]      data           Custom log data.
  # @attr [DateTime]  processing_at  Timestamp of {Dispatch} processing.
  #                                  Can be either future (when in +scheduled+ state) or past.
  class Log < ActiveRecord::Base
    AVAILABLE_STATUSES = [:scheduled, :delivered, :skipped, :error]

    belongs_to  :entity,        polymorphic: true
    belongs_to  :mailing,       class_name: "RoRmaily::Dispatch", foreign_key: :mailing_id

    validates   :entity,        presence: true
    validates   :mailing,       presence: true
    validates   :status,        presence: true, inclusion: {in: AVAILABLE_STATUSES}

    validates   :processing_at, presence: true, if: :scheduled?

    scope       :ordered,       lambda { order("processing_at asc") }
    scope       :for_entity,    lambda {|entity| where(entity_id: entity.id, entity_type: entity.class.base_class) }
    scope       :for_mailing,   lambda {|mailing| where(mailing_id: mailing.id) }
    scope       :for_mailings,  lambda {|mailings| where("mailing_id in (?)", mailings) }
    scope       :delivered,     lambda { where(status: :delivered) }
    scope       :skipped,       lambda { where(status: :skipped) }
    scope       :error,         lambda { where(status: :error) }
    scope       :scheduled,     lambda { where(status: :scheduled) }
    scope       :processed,     lambda { where(status: [:delivered, :skipped, :error]) }

    serialize   :data,          Hash

    if Rails::VERSION::MAJOR == 3
      attr_accessible :status, :data
    end

    # Creates Log object for given {Dispatch} and entity.
    #
    # @param mailing [Dispatch]
    # @param entity [ActiveRecord::Base]
    # @param attributes [Hash] log attributes
    # @option attributes [Time] :processing_at (DateTime.now)
    # @option attributes [Symbol] :status
    # @option attributes [Hash] :data
    def self.create_for mailing, entity, attributes = {}
      log = Log.new
      log.set_attributes_for mailing, entity, attributes
      log.save!
      log
    end

    # Sets Log instance attributes.
    #
    # @param mailing [Dispatch]
    # @param entity [ActiveRecord::Base]
    # @param attributes [Hash] log attributes
    # @option attributes [Time] :processing_at (DateTime.now)
    # @option attributes [Symbol] :status
    # @option attributes [Hash] :data
    def set_attributes_for mailing, entity, attributes = {}
      self.mailing = mailing
      self.entity = entity
      self.entity_email = mailing.destination(entity)

      self.processing_at = attributes[:processing_at] || DateTime.now
      self.status = attributes[:status]
      self.data = attributes[:data]
    end

    def status
      read_attribute(:status).to_sym
    end

    def delivered?
      self.status == :delivered
    end

    def skipped?
      self.status == :skipped
    end

    def error?
      self.status == :error
    end

    def scheduled?
      self.status == :scheduled
    end
  end
end
