# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::Outbound::Text do
  let(:adapter) { described_class.new }
  let(:whats_app_phone_number) { '+491511234567' }
  let(:valid_account_sid) { 'VALID_ACCOUNT_SID' }
  let(:valid_api_key_sid) { 'VALID_API_KEY_SID' }
  let(:valid_api_key_secret) { 'VALID_API_KEY_SECRET' }
  let(:mock_twilio_rest_client) { instance_double(Twilio::REST::Client) }
  let(:messages_double) { double(Twilio::REST::Api::V2010::AccountContext::MessageInstance) }
  let(:contributor) do
    create(:contributor, whats_app_phone_number: whats_app_phone_number, email: nil)
  end
  let(:message) { create(:message, recipient: contributor) }
  let(:expected_params) do
    { from: "whatsapp:#{Setting.whats_app_server_phone_number}", body: message.text, to: "whatsapp:#{contributor.whats_app_phone_number}" }
  end

  describe '#perform' do
    subject { -> { adapter.perform(contributor_id: message.recipient.id, text: message.text) } }

    before do
      allow(Setting).to receive(:twilio_account_sid).and_return(valid_account_sid)
      allow(Setting).to receive(:twilio_api_key_sid).and_return(valid_api_key_sid)
      allow(Setting).to receive(:twilio_api_key_secret).and_return(valid_api_key_secret)
      allow(Twilio::REST::Client).to receive(:new).with(valid_api_key_sid, valid_api_key_secret,
                                                        valid_account_sid).and_return(mock_twilio_rest_client)
      allow(mock_twilio_rest_client).to receive(:messages).and_return(messages_double)
      allow(messages_double).to receive(:create)
    end

    it 'creates the message' do
      expect(messages_double).to receive(:create).with(expected_params)

      subject.call
    end
  end
end
