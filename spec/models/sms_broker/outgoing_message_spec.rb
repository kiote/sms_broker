require 'spec_helper'

module SmsBroker
  describe OutgoingMessage do

    describe "after_create" do
      after(:each) { SmsBroker::OutgoingMessage.class_variable_set :@@after_create_hooks, Array.new }

      it 'should trigger the registered hooks' do
        hook = double(:hook)
        hook.should_receive(:execute)

        SmsBroker::OutgoingMessage.register_after_create_hook(hook)

        subject.run_callbacks(:create)
      end
    end

    describe "after_initialize" do
      it "sets status to NEW" do
        subject.status.should == OutgoingMessage::NEW
      end

      it "sets delivery_attempts to 0" do
        subject.delivery_attempts.should == 0
      end

      it "does not set sender default value is not set" do
        OutgoingMessage.new.sender.should == nil
      end

      it "sets sender to configured default when default value is set" do
        SmsBroker.config do |c|
          c.stub(:default_sender) { "TestSender" }
        end

        OutgoingMessage.new.sender.should == "TestSender"
      end

      context "has locale" do
        before do
          SmsBroker.config do |c|
            c.stub(:locale) { :nb }
          end
        end

        let(:outgoing_message) { OutgoingMessage.new }

        it "changes recipient number for 8-digits" do
          outgoing_message.recipient = "12345678"
          outgoing_message.recipient.should == "4712345678"
        end

        it "does not change recipient number for any otehr amount of digits" do
          outgoing_message.recipient = "123456789"
          outgoing_message.recipient.should == "123456789"
        end
      end

      it "does not change recipient number format if locale is not set" do
        outgoing_message = OutgoingMessage.new
        outgoing_message.recipient = "12345678"
        outgoing_message.recipient.should == "12345678"
      end
    end

    describe ".build_from_incoming" do
      it "uses incoming message to set up new object" do
        incoming_message = build :incoming_message, id: 1

        outgoing_message = OutgoingMessage.build_from_incoming(incoming_message)

        outgoing_message.incoming_message.should == incoming_message
        outgoing_message.recipient.should == incoming_message.sender
      end
    end
  end
end
