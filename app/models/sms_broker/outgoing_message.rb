module SmsBroker
  class OutgoingMessage < ActiveRecord::Base
    belongs_to :incoming_message

    validates :recipient, :sender, :text, presence: true

    after_initialize :init
    after_create :fire_hooks

    NEW       = 'NEW'
    RETRYING  = 'RETRYING'
    SENT      = 'SENT'
    FAILED    = 'FAILED'

    NORWAY_PHONE_CODE = '47'

    scope :sent,   -> { where(status: SENT) }
    scope :unsent, -> { where('status != ?', SENT) }

    @@after_create_hooks = Array.new

    def init
      if SmsBroker.config.respond_to? :default_sender
        self.sender ||= SmsBroker.config.default_sender
      end

      self.status ||= SmsBroker::OutgoingMessage::NEW
      self.delivery_attempts ||= 0
    end

    def recipient=(recipient_number)
      if SmsBroker.config.respond_to? :locale
        self[:recipient] = localized_number(recipient_number, SmsBroker.config.locale)
      else
        self[:recipient] = recipient_number
      end
    end

    def self.register_after_create_hook(hook)
      unless @@after_create_hooks.include?(hook)
        @@after_create_hooks << hook
      end
    end

    def self.build_from_incoming(incoming_message)
      message = OutgoingMessage.new
      message.incoming_message = incoming_message
      message.recipient = incoming_message.sender

      message
    end

  private

    def fire_hooks
      @@after_create_hooks.each do |hook|
        hook.execute(self)
      end
    end

    def localized_number(number, locale)
      return number unless locale == :nb

      return NORWAY_PHONE_CODE + number if number.length == 8

      return number
    end
  end
end
