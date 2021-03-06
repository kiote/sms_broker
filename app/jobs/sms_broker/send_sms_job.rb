module SmsBroker
  class SendSmsJob < Struct.new(:message, :test_mode)

    def perform
      message.increment(:delivery_attempts)

      begin
        if test_mode
          return true
        else
          return SmsSender.new.send(message)
        end
      rescue Exception => e
        raise("Unable to deliver SMS to gateway: #{e.message}")
      end
    end

    def success(job)
      message.status = OutgoingMessage::SENT
    end

    def failure(job)
      message.status = OutgoingMessage::FAILED
    end

    def after(job)
      message.save!
    end

    def error(job, exception)
      message.status = OutgoingMessage::RETRYING
    end

  end
end