# frozen_string_literal: true

# frozen_string_literal: true, frozen

require 'rails_helper'

RSpec.describe WhatsAppAdapter::TwilioInbound do
  let(:adapter) { described_class.new }
  let(:whats_app_phone_number) { '+491511234567' }
  let(:twilio_message_sid) { 'someValidMessageSid' }
  let(:original_message_sid) { 'someUniqueSid' }
  let(:organization) { create(:organization) }
  let!(:contributor) { create(:contributor, whats_app_phone_number: whats_app_phone_number, organization: organization) }
  let(:whats_app_message) do
    {
      'AccountSid' => 'someAccount',
      'ApiVersion' => '2010-04-01',
      'Body' => 'Antworten',
      'ButtonPayload' => 'Antworten-Payload',
      'ButtonText' => 'Antworten',
      'From' => "whatsapp:#{whats_app_phone_number}",
      'MessageSid' => twilio_message_sid,
      'NumMedia' => '0',
      'NumSegments' => '1',
      'OriginalRepliedMessageSender' => "whatsapp:#{organization.whats_app_server_phone_number}",
      'OriginalRepliedMessageSid' => original_message_sid,
      'ProfileName' => 'Matthew Rider',
      'ReferralNumMedia' => '0',
      'SmsMessageSid' => twilio_message_sid,
      'SmsSid' => twilio_message_sid,
      'SmsStatus' => 'received',
      'To' => "whatsapp:#{organization.whats_app_server_phone_number}",
      'WaId' => '491511234567'
    }.transform_keys(&:underscore)
  end
  let(:quote_response) do
    {
      'AccountSid' => 'someAccount',
      'ApiVersion' => '2010-04-01',
      'Body' => 'This is simply a quote reply',
      'From' => "whatsapp:#{whats_app_phone_number}",
      'MessageSid' => twilio_message_sid,
      'NumMedia' => '0',
      'NumSegments' => '1',
      'OriginalRepliedMessageSender' => "whatsapp:#{organization.whats_app_server_phone_number}",
      'OriginalRepliedMessageSid' => original_message_sid,
      'ProfileName' => 'Matthew Rider',
      'ReferralNumMedia' => '0',
      'SmsMessageSid' => twilio_message_sid,
      'SmsSid' => twilio_message_sid,
      'SmsStatus' => 'received',
      'To' => "whatsapp:#{organization.whats_app_server_phone_number}",
      'WaId' => '491511234567'
    }.transform_keys(&:underscore)
  end

  describe '#on' do
    describe 'REQUEST_TO_RECEIVE_MESSAGE' do
      let(:request_to_receive_message_callback) { spy('request_to_receive_message_callback') }

      before do
        adapter.on(WhatsAppAdapter::TwilioInbound::REQUEST_TO_RECEIVE_MESSAGE) do |sender, original_replied_message_sid|
          request_to_receive_message_callback.call(sender, original_replied_message_sid)
        end
      end

      subject do
        adapter.consume(whats_app_message)
        request_to_receive_message_callback
      end

      context 'given a quick reply message is received' do
        it { is_expected.to have_received(:call).with(contributor, original_message_sid) }
      end

      context 'given a reply to a message that is not a quick reply is received' do
        let(:whats_app_message) { quote_response }
        it { is_expected.not_to have_received(:call).with(contributor, original_message_sid) }
      end
    end
  end
end
