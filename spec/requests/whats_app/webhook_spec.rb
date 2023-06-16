# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsApp::WebhookController do
  let(:auth_token) { 'valid_auth_token' }
  let(:mock_twilio_security_request_validator) { instance_double(Twilio::Security::RequestValidator) }
  let(:whats_app_phone_number) { '+491511234567' }
  let(:params) do
    {
      'AccountSid' => 'someAccount',
      'ApiVersion' => '2010-04-01',
      'Body' => 'Hello',
      'From' => "whatsapp:#{whats_app_phone_number}",
      'MessageSid' => 'someId',
      'NumMedia' => '0',
      'NumSegments' => '1',
      'ProfileName' => 'Matthew Rider',
      'ReferralNumMedia' => '0',
      'SmsMessageSid' => 'someId',
      'SmsSid' => 'someId',
      'SmsStatus' => 'received',
      'To' => "whatsapp:#{Setting.whats_app_server_phone_number}",
      'WaId' => '491511234567'
    }
  end

  subject { -> { post whats_app_webhook_path, params: params } }

  describe '#message' do
    before do
      allow(Sentry).to receive(:capture_exception)
      allow(Setting).to receive(:whats_app_server_phone_number).and_return('4915133311445')
      allow(Twilio::Security::RequestValidator).to receive(:new).and_return(mock_twilio_security_request_validator)
    end

    describe 'fails Rack::TwilioWebhookAuthentication' do
      before do
        allow(mock_twilio_security_request_validator).to receive(:validate).and_return(false)
      end

      it 'returns forbidden' do
        subject.call
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns message why it failed' do
        subject.call
        expect(response.body).to eq('Twilio Request Validation Failed.')
      end
    end

    describe 'unknown contributor' do
      before do
        allow(mock_twilio_security_request_validator).to receive(:validate).and_return(true)
      end

      it 'does not create a message' do
        expect { subject.call }.not_to change(Message, :count)
      end

      it 'raises an error' do
        expect(Sentry).to receive(:capture_exception).with(
          WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: '+491511234567')
        )

        subject.call
      end
    end

    describe 'given a contributor' do
      let!(:contributor) { create(:contributor, whats_app_phone_number: whats_app_phone_number) }
      let(:request) { create(:request) }

      before do
        allow(mock_twilio_security_request_validator).to receive(:validate).and_return(true)
        create(:message, request: request, recipient: contributor)
      end

      context 'no message template sent' do
        it 'creates a messsage' do
          expect { subject.call }.to change(Message, :count).from(1).to(2)
        end
      end

      context 'responding to template' do
        before { params['Body'] = 'Antworten' }
        let(:expected_job_args) { { recipient: contributor, text: contributor.received_messages.first.text } }

        it 'enqueues a job to send the latest received message' do
          expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::Outbound::Text).on_queue('default').with(expected_job_args)
        end
      end
    end
  end
end
