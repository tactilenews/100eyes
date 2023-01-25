# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::Outbound::File do
  let(:adapter) { described_class.new }
  let(:whats_app_phone_number) { '+491511234567' }
  let(:valid_account_sid) { 'VALID_ACCOUNT_SID' }
  let(:valid_auth_token) { 'VALID_AUTH_TOKEN' }
  let(:mock_twilio_rest_client) { instance_double(Twilio::REST::Client) }
  let(:messages_double) { double(Twilio::REST::Api::V2010::AccountContext::MessageInstance) }
  let(:contributor) do
    create(:contributor, whats_app_phone_number: whats_app_phone_number, email: nil)
  end
  let(:message) { create(:message, recipient: contributor, files: [create(:file)]) }
  let(:expected_params) do
    { from: "whatsapp:#{Setting.whats_app_server_phone_number}",
      body: message.text,
      to: "whatsapp:#{contributor.whats_app_phone_number}",
      media_url: Rails.application.routes.url_helpers.rails_blob_url(message.files.first.attachment.blob, host: Setting.application_host) }
  end

  describe '#perform' do
    subject { -> { adapter.perform(recipient: message.recipient, text: message.text, file: message.files.first) } }

    before do
      allow(Setting).to receive(:twilio_account_sid).and_return(valid_account_sid)
      allow(Setting).to receive(:twilio_auth_token).and_return(valid_auth_token)
      allow(Twilio::REST::Client).to receive(:new).with(valid_account_sid, valid_auth_token).and_return(mock_twilio_rest_client)
      allow(mock_twilio_rest_client).to receive(:messages).and_return(messages_double)
      allow(messages_double).to receive(:create)
    end

    it 'creates the message' do
      expect(messages_double).to receive(:create).with(expected_params)

      subject.call
    end
  end
end
