# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::Outbound::Text do
  let(:adapter) { described_class.new }
  let(:whats_app_phone_number) { '+491511234567' }
  let(:valid_account_sid) { 'VALID_ACCOUNT_SID' }
  let(:valid_api_key_sid) { 'VALID_API_KEY_SID' }
  let(:valid_api_key_secret) { 'VALID_API_KEY_SECRET' }
  let(:mock_twilio_rest_client) { instance_double(Twilio::REST::Client) }
  let(:message_list_double) { instance_double(Twilio::REST::Api::V2010::AccountContext::MessageList) }
  let(:messages_double) { double(Twilio::REST::Api::V2010::AccountContext::MessageInstance, sid: twilio_message_sid) }
  let(:contributor) do
    create(:contributor, whats_app_phone_number: whats_app_phone_number, email: nil)
  end
  let(:message) { create(:message, recipient: contributor) }
  let(:expected_params) do
    { from: "whatsapp:#{Setting.whats_app_server_phone_number}", body: text, to: "whatsapp:#{contributor.whats_app_phone_number}" }
  end
  let(:twilio_message_sid) { 'valid_twilio_message_sid' }

  describe '#perform' do
    before do
      allow(Setting).to receive(:twilio_account_sid).and_return(valid_account_sid)
      allow(Setting).to receive(:twilio_api_key_sid).and_return(valid_api_key_sid)
      allow(Setting).to receive(:twilio_api_key_secret).and_return(valid_api_key_secret)
      allow(Twilio::REST::Client).to receive(:new).with(valid_api_key_sid, valid_api_key_secret,
                                                        valid_account_sid).and_return(mock_twilio_rest_client)
      allow(mock_twilio_rest_client).to receive(:messages).and_return(message_list_double)
      allow(message_list_double).to receive(:create).and_return(messages_double)
      allow(messages_double).to receive(:create)
    end

    context 'given simply text' do
      subject { -> { adapter.perform(contributor_id: message.recipient.id, text: text) } }

      let(:text) { 'Welcome to 100eyes' }

      it 'creates the message' do
        expect(message_list_double).to receive(:create).with(expected_params)

        subject.call
      end
    end

    context 'given a Message instance' do
      subject { -> { adapter.perform(contributor_id: message.recipient.id, text: text, message: message) } }

      let(:text) { message.text }

      it 'creates the message' do
        expect(message_list_double).to receive(:create).with(expected_params)

        subject.call
      end

      it 'saves the external id' do
        expect { subject.call }.to change { message.reload.external_id }.from(nil).to(twilio_message_sid)
      end
    end
  end
end
