# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::TwilioOutbound::Text do
  let(:adapter) { described_class.new }
  let(:valid_account_sid) { 'VALID_ACCOUNT_SID' }
  let(:valid_api_key_sid) { 'VALID_API_KEY_SID' }
  let(:valid_api_key_secret) { 'VALID_API_KEY_SECRET' }
  let(:mock_twilio_rest_client) { instance_double(Twilio::REST::Client) }
  let(:message_list_double) { instance_double(Twilio::REST::Api::V2010::AccountContext::MessageList) }
  let(:messages_double) { double(Twilio::REST::Api::V2010::AccountContext::MessageInstance, sid: twilio_message_sid) }
  let(:organization) do
    create(:organization, twilio_account_sid: valid_account_sid, twilio_api_key_sid: valid_api_key_sid,
                          twilio_api_key_secret: valid_api_key_secret)
  end
  let(:contributor) do
    create(:contributor, :whats_app_contributor, organization: organization)
  end
  let(:organization_id) { organization.id }
  let(:contributor_id) { contributor.id }
  let(:expected_params) do
    { from: "whatsapp:#{organization.whats_app_server_phone_number}", body: text, to: "whatsapp:#{contributor.whats_app_phone_number}" }
  end
  let(:twilio_message_sid) { 'valid_twilio_message_sid' }
  let(:text) { 'Default text' }
  let(:message) { nil }

  describe '#perform' do
    subject { -> { adapter.perform(organization_id: organization_id, contributor_id: contributor_id, text: text, message: message) } }

    before do
      allow(Twilio::REST::Client).to receive(:new).with(valid_api_key_sid, valid_api_key_secret,
                                                        valid_account_sid).and_return(mock_twilio_rest_client)
      allow(mock_twilio_rest_client).to receive(:messages).and_return(message_list_double)
      allow(message_list_double).to receive(:create).and_return(messages_double)
      allow(messages_double).to receive(:create)
    end

    context 'given simply text' do
      let(:text) { 'Welcome to 100eyes' }

      it 'creates the message' do
        expect(message_list_double).to receive(:create).with(expected_params)

        subject.call
      end
    end

    context 'given a Message instance' do
      let(:message) { create(:message, recipient: contributor) }
      let(:text) { message.text }

      it 'creates the message' do
        expect(message_list_double).to receive(:create).with(expected_params)

        subject.call
      end

      it 'saves the external id' do
        expect { subject.call }.to change { message.reload.external_id }.from(nil).to(twilio_message_sid)
      end
    end

    describe 'Unknown organization' do
      let(:organization_id) { 564_321 }

      it 'reports the error' do
        expect(Sentry).to receive(:capture_exception).with(ActiveRecord::RecordNotFound)

        subject.call
      end
    end

    describe 'Unknown contributor' do
      let(:contributor_id) { 564_321 }

      it 'reports the error' do
        expect(Sentry).to receive(:capture_exception).with(ActiveRecord::RecordNotFound)

        subject.call
      end

      context 'not part of organization' do
        let(:contributor_id) { create(:contributor).id }

        it 'reports the error' do
          expect(Sentry).to receive(:capture_exception).with(ActiveRecord::RecordNotFound)

          subject.call
        end
      end
    end
  end
end
