# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsApp::WebhookController do
  let(:auth_token) { 'valid_auth_token' }
  let(:mock_twilio_security_request_validator) { instance_double(Twilio::Security::RequestValidator) }
  let(:whats_app_phone_number) { '+491511234567' }

  describe '#message' do
    subject { -> { post whats_app_webhook_path, params: params } }

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

    before do
      allow(Sentry).to receive(:capture_exception)
      allow(Setting).to receive(:whats_app_server_phone_number).and_return('4915133311445')
      allow(Twilio::Security::RequestValidator).to receive(:new).and_return(mock_twilio_security_request_validator)
      allow(Request).to receive(:broadcast!).and_call_original
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

      it 'returns 200' do
        subject.call

        expect(response).to have_http_status(:ok)
      end

      context 'no message template sent' do
        it 'creates a messsage' do
          expect { subject.call }.to change(Message, :count).from(2).to(3)
        end
      end

      context 'responding to template' do
        before { contributor.update(whats_app_message_template_sent_at: Time.current) }

        let(:latest_message_job_args) { { contributor_id: contributor.id, text: contributor.received_messages.first.text } }

        context 'request to receive latest message' do
          it 'enqueues a job to send the latest received message' do
            expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::Outbound::Text).on_queue('default').with(latest_message_job_args)
          end

          describe 'replying to message with quick reply button' do
            let!(:previous_request) { create(:request, title: 'Previous request', text: 'I have previous text') }
            let!(:newer_request) { create(:request, title: 'Newer request', text: 'I have newer text') }
            let(:valid_account_sid) { 'VALID_ACCOUNT_SID' }
            let(:valid_api_key_sid) { 'VALID_API_KEY_SID' }
            let(:valid_api_key_secret) { 'VALID_API_KEY_SECRET' }
            let(:mock_twilio_rest_client) { instance_double(Twilio::REST::Client) }
            let(:messages_double) { double(Twilio::REST::Api::V2010::AccountContext::MessageInstance, body: body_text) }

            before do
              subject.call
              params['OriginalRepliedMessageSid'] = 'someUniqueId'
              allow(Twilio::REST::Client).to receive(:new).and_return(mock_twilio_rest_client)
              allow(mock_twilio_rest_client).to receive(:messages).with('someUniqueId').and_return(messages_double)
              allow(messages_double).to receive(:fetch).and_return(messages_double)
            end

            describe 'previous request' do
              let(:requested_message_job_args) do
                { contributor_id: contributor.id, text: previous_request.messages.where(recipient_id: contributor.id).first.text }
              end
              let(:body_text) do
                "Some template message with request title „#{previous_request.title}“. Wenn du antworten möchtest, klicke auf 'Antworten'."
              end

              it 'enqueues a job to send the requested message' do
                expect do
                  subject.call
                end.to have_enqueued_job(WhatsAppAdapter::Outbound::Text).on_queue('default').with(requested_message_job_args)
              end
            end

            describe 'newer request' do
              let(:requested_message_job_args) do
                { contributor_id: contributor.id, text: newer_request.messages.where(recipient_id: contributor.id).first.text }
              end
              let(:body_text) do
                "Some template message with request title „#{newer_request.title}“. Wenn du antworten möchtest, klicke auf 'Antworten'."
              end

              it 'enqueues a job to send the requested message' do
                expect do
                  subject.call
                end.to have_enqueued_job(WhatsAppAdapter::Outbound::Text).on_queue('default').with(requested_message_job_args)
              end
            end

            describe 'cannot determine request from original message' do
              let(:body_text) { 'Does not contain German quotes, or request cannot be found by title' }

              it 'enqueues a job to send the latest received message' do
                expect do
                  subject.call
                end.to have_enqueued_job(WhatsAppAdapter::Outbound::Text).on_queue('default').with(latest_message_job_args)
              end
            end
          end
        end

        context 'request for more info' do
          before { params['Body'] = 'Mehr Infos' }

          let(:more_info_job_args) do
            { contributor_id: contributor.id, text: [Setting.about, "_#{I18n.t('adapter.shared.unsubscribe.instructions')}_"].join("\n\n") }
          end

          it 'enqueues a job to send more info message' do
            expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::Outbound::Text).on_queue('default').with(more_info_job_args)
          end

          it 'does not enqueue a job to send the latest received message' do
            expect { subject.call }.not_to have_enqueued_job(WhatsAppAdapter::Outbound::Text).with(latest_message_job_args)
          end
        end

        context 'request to unsubscribe' do
          before { params['Body'] = 'Abbestellen' }

          it { is_expected.to have_enqueued_job(UnsubscribeContributorJob).with(contributor.id, WhatsAppAdapter::Outbound) }
        end

        context 'request to re-subscribe' do
          before do
            contributor.update(unsubscribed_at: Time.current)
            params['Body'] = 'Bestellen'
          end

          it { is_expected.to have_enqueued_job(ResubscribeContributorJob).with(contributor.id, WhatsAppAdapter::Outbound) }
        end
      end
    end
  end

  describe '#status' do
    subject { -> { post whats_app_status_path, params: params } }

    let(:params) do
      {
        'AccountSid' => 'someAccountSID',
        'ApiVersion' => '2010-04-01',
        'ChannelInstallSid' => 'someChannelInstallSid',
        'ChannelPrefix' => 'whatsapp',
        'ChannelToAddress' => whats_app_phone_number.to_s,
        'ErrorCode' => '60228',
        'ErrorMessage' => 'Template was not found',
        'From' => "whatsapp:#{Setting.whats_app_server_phone_number}",
        'MessageSid' => 'someSid',
        'MessageStatus' => 'failed',
        'SmsSid' => 'someSid',
        'SmsStatus' => 'failed',
        'StructuredMessage' => 'false',
        'To' => "whatsapp:#{whats_app_phone_number}"
      }
    end

    let(:exception) do
      WhatsAppAdapter::MessageDeliveryUnsuccessfulError.new(status: params['MessageStatus'],
                                                            whats_app_phone_number: whats_app_phone_number, message: params['ErrorMessage'])
    end

    before { allow(Twilio::Security::RequestValidator).to receive(:new).and_return(mock_twilio_security_request_validator) }

    describe 'fails Rack::TwilioWebhookAuthentication' do
      before { allow(mock_twilio_security_request_validator).to receive(:validate).and_return(false) }

      it 'returns forbidden' do
        subject.call
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns message why it failed' do
        subject.call
        expect(response.body).to eq('Twilio Request Validation Failed.')
      end
    end

    describe 'passes Rack::TwilioWebhookAuthentication' do
      before { allow(mock_twilio_security_request_validator).to receive(:validate).and_return(true) }

      it 'returns 200' do
        subject.call

        expect(response).to have_http_status(:ok)
      end

      describe 'given an unknown contributor' do
        it 'does not report it as an error, as it is not actionable' do
          expect(Sentry).not_to receive(:capture_exception)

          subject.call
        end

        context 'due to an invalid message recipient error' do
          it { is_expected.not_to have_enqueued_job(MarkInactiveContributorInactiveJob) }
        end
      end

      describe 'given a known contributor' do
        let!(:contributor) { create(:contributor, whats_app_phone_number: whats_app_phone_number) }

        describe 'given a failed message delivery' do
          it 'reports the error with the error message' do
            expect(Sentry).to receive(:capture_exception).with(exception)

            subject.call
          end

          context 'due to an invalid message recipient error' do
            before do
              params['ErrorCode'] = '63024'
              params['ErrorMessage'] = 'Twilio Error: Invalid message recipient. Generated new message with sid: someSid'
            end

            it 'does not report it as an error, as it is not actionable' do
              expect(Sentry).not_to receive(:capture_exception)

              subject.call
            end

            it {
              expect(subject).to have_enqueued_job(MarkInactiveContributorInactiveJob).with do |params|
                expect(params[:contributor_id]).to eq(contributor.id)
              end
            }
          end

          context 'due to a freeform message not allowed error' do
            let!(:request) do
              create(:request, title: 'I failed to send', text: 'Hey {{FIRST_NAME}}, because it was sent outside the allowed window')
            end
            let(:valid_account_sid) { 'VALID_ACCOUNT_SID' }
            let(:valid_api_key_sid) { 'VALID_API_KEY_SID' }
            let(:valid_api_key_secret) { 'VALID_API_KEY_SECRET' }
            let(:mock_twilio_rest_client) { instance_double(Twilio::REST::Client) }
            let(:messages_double) { double(Twilio::REST::Api::V2010::AccountContext::MessageInstance, body: body_text) }
            let(:body_text) { 'no message with this text saved' }
            let(:freeform_message_not_allowed_error_message) do
              'Twilio Error: Failed to send freeform message because you are outside the allowed window.'
            end

            before do
              allow(Twilio::REST::Client).to receive(:new).and_return(mock_twilio_rest_client)
              allow(mock_twilio_rest_client).to receive(:messages).with('someSid').and_return(messages_double)
              allow(messages_double).to receive(:fetch).and_return(messages_double)
              params['ErrorCode'] = '63016'
              params['ErrorMessage'] = freeform_message_not_allowed_error_message
            end

            it 'reports it as an error, as we want to track specifics to when this occurs' do
              expect(Sentry).to receive(:capture_exception).with(exception)

              subject.call
            end

            it 'given message cannot be found by Twilio message sid body' do
              expect { subject.call }.not_to have_enqueued_job(WhatsAppAdapter::Outbound::Text)
              expect { subject.call }.not_to raise_error
            end

            describe 'given a message is found by Twilio message sid body' do
              let!(:message) { create(:message, text: body_text, request: request) }
              let(:body_text) { "Hey #{contributor.first_name}, because it was sent outside the allowed window" }

              it 'enqueues the Text job with WhatsApp template' do
                expect { subject.call }.to(have_enqueued_job(WhatsAppAdapter::Outbound::Text).on_queue('default').with do |params|
                  expect(params[:contributor_id]).to eq(contributor.id)
                  expect(params[:text]).to include(contributor.first_name)
                  expect(params[:text]).to include(message.request.title)
                end)
              end

              context 'given an undelivered status' do
                before { params['MessageStatus'] = 'undelivered' }

                it 'is expected not to schedule a job as it would send out twice, one for undelivered and one for failed' do
                  expect { subject.call }.not_to have_enqueued_job(WhatsAppAdapter::Outbound::Text)
                end
              end
            end
          end
        end
      end
    end
  end

  describe '#errors' do
    subject { -> { post whats_app_errors_path, params: params } }

    let(:url) { 'https://example.100ey.es/whats_app/webhook' }
    let(:error_payload) do
      {
        'error_code' => '21408',
        'more_info' => {
          'ErrorCode' => '21408',
          'LogLevel' => 'ERROR',
          'Msg' => 'Got HTTP 404 response to https://example.100ey.es/twilio/voice',
          'url' => url
        },
        'webhook' => {
          'request' => {
            'url' => url,
            'parameters' => {
              'MessageSid' => 'someMessageSid'
            }
          }
        }
      }
    end
    let(:params) do
      {
        'AccountSid' => 'someAccountSid',
        'Level' => 'ERROR',
        'ParentAccountSid' => 'someParentAccountSid',
        'Payload' => error_payload.to_json,
        'PayloadType' => 'application/json',
        'Sid' => 'someSid',
        'Timestamp' => Time.current.to_i
      }
    end
    let(:exception) do
      WhatsAppAdapter::TwilioError.new(error_code: error_payload['error_code'],
                                       message: error_payload['more_info']['Msg'],
                                       url: error_payload['more_info']['url'])
    end

    before { allow(Twilio::Security::RequestValidator).to receive(:new).and_return(mock_twilio_security_request_validator) }

    describe 'fails Rack::TwilioWebhookAuthentication' do
      before { allow(mock_twilio_security_request_validator).to receive(:validate).and_return(false) }

      it 'returns forbidden' do
        subject.call
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns message why it failed' do
        subject.call
        expect(response.body).to eq('Twilio Request Validation Failed.')
      end
    end

    describe 'passes Rack::TwilioWebhookAuthentication' do
      before { allow(mock_twilio_security_request_validator).to receive(:validate).and_return(true) }

      it 'returns 200' do
        subject.call

        expect(response).to have_http_status(:ok)
      end

      it 'reports the error with error code, message, and url' do
        expect(Sentry).to receive(:capture_exception).with(exception)

        subject.call
      end

      context 'given more_info is not provided' do
        before { error_payload.delete('more_info') }

        let(:exception) do
          WhatsAppAdapter::TwilioError.new(error_code: error_payload['error_code'])
        end

        it 'reports the error with error code' do
          expect(Sentry).to receive(:capture_exception).with(exception)

          subject.call
        end
      end
    end
  end
end
