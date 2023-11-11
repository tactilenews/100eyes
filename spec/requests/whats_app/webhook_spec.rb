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
          let!(:admin) { create_list(:user, 2, admin: true) }
          let!(:non_admin_user) { create(:user) }

          before { params['Body'] = 'Abbestellen' }
          let(:sucessful_unsubscribe_job_args) do
            { contributor_id: contributor.id,
              text: [I18n.t('adapter.shared.unsubscribe.successful'),
                     "_#{I18n.t('adapter.shared.subscribe.instructions')}_"].join("\n\n") }
          end

          it 'marks contributor as unsubscribed' do
            expect { subject.call }.to change { contributor.reload.unsubscribed_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
          end

          it 'enqueues a job to inform the contributor of successful unsubscribe' do
            expect do
              subject.call
            end.to have_enqueued_job(WhatsAppAdapter::Outbound::Text).on_queue('default').with(sucessful_unsubscribe_job_args)
          end

          it_behaves_like 'an ActivityNotification', 'ContributorMarkedInactive'

          it 'enqueues a job to inform admin' do
            expect { subject.call }.to have_enqueued_job.on_queue('default').with(
              'PostmarkAdapter::Outbound',
              'contributor_marked_as_inactive_email',
              'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
              {
                params: { admin: an_instance_of(User), contributor: contributor },
                args: []
              }
            ).exactly(2).times
          end

          it 'does not enqueue a job to send the latest received message' do
            expect { subject.call }.not_to have_enqueued_job(WhatsAppAdapter::Outbound::Text).with(latest_message_job_args)
          end
        end

        context 'request to re-subscribe' do
          let!(:admin) { create_list(:user, 2, admin: true) }
          let!(:non_admin_user) { create(:user) }

          before do
            contributor.update(unsubscribed_at: Time.current)
            params['Body'] = 'Bestellen'
          end

          let(:sucessful_subscribe_job_args) do
            { contributor_id: contributor.id, text: I18n.t('adapter.whats_app.welcome_message', project_name: Setting.project_name) }
          end

          it 'marks contributor as active' do
            expect { subject.call }.to change { contributor.reload.unsubscribed_at }.from(kind_of(ActiveSupport::TimeWithZone)).to(nil)
          end

          it 'marks that contributor has responded to template message' do
            expect { subject.call }.to change {
                                         contributor.reload.whats_app_message_template_responded_at
                                       }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
          end

          it 'enqueues a job to welcome contributor' do
            expect do
              subject.call
            end.to have_enqueued_job(WhatsAppAdapter::Outbound::Text).on_queue('default').with(sucessful_subscribe_job_args)
          end

          it_behaves_like 'an ActivityNotification', 'ContributorSubscribed'

          it 'enqueues a job to inform admin' do
            expect { subject.call }.to have_enqueued_job.on_queue('default').with(
              'PostmarkAdapter::Outbound',
              'contributor_subscribed_email',
              'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
              {
                params: { admin: an_instance_of(User), contributor: contributor },
                args: []
              }
            ).exactly(2).times
          end

          it 'does not enqueue a job to send the latest received message' do
            expect { subject.call }.not_to have_enqueued_job(WhatsAppAdapter::Outbound::Text).with(latest_message_job_args)
          end
        end
      end
    end
  end
end
