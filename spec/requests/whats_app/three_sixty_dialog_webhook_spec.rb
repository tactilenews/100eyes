# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsApp::ThreeSixtyDialogWebhookController do
  let(:whats_app_phone_number) { '+491511234567' }
  let(:params) do
    { contacts: [{ profile: { name: 'Matthew Rider' },
                   wa_id: '491511234567' }],
      messages: [{ from: '491511234567',
                   id: 'some_valid_id',
                   text: { body: 'Hey' },
                   timestamp: '1692118778',
                   type: 'text' }],
      three_sixty_dialog_webhook: { contacts: [{ profile: { name: 'Matthew Rider' },
                                                 wa_id: '491511234567' }],
                                    messages: [{ from: '491511234567',
                                                 id: 'some_valid_id',
                                                 text: { body: 'Hey' },
                                                 timestamp: '1692118778',
                                                 type: 'text' }] } }
  end
  let(:text_payload) do
    {
      payload: {
        recipient_type: 'individual',
        to: contributor.whats_app_phone_number.split('+').last,
        type: 'text',
        text: {
          body: text
        }
      }
    }
  end
  let(:latest_message) { contributor.received_messages.first.text }

  subject { -> { post whats_app_three_sixty_dialog_webhook_path, params: params } }

  describe '#messages' do
    before do
      allow(Sentry).to receive(:capture_exception)
      allow(Setting).to receive(:whats_app_server_phone_number).and_return('4915133311445')
      allow(Request).to receive(:broadcast!).and_call_original
      allow(Setting).to receive(:three_sixty_dialog_client_api_key).and_return('valid_api_key')
    end

    describe 'statuses' do
      let(:params) do
        {
          statuses: [{ id: 'some_valid_id',
                       message: { recipient_id: '491511234567' },
                       status: 'read',
                       timestamp: '1691405467',
                       type: 'message' }],
          three_sixty_dialog_webhook: { statuses: [{ id: 'some_valid_id',
                                                     message: { recipient_id: '491511234567' },
                                                     status: 'read', timestamp: '1691405467',
                                                     type: 'message' }] }
        }
      end

      it 'ignores statuses' do
        expect(WhatsAppAdapter::ThreeSixtyDialogInbound).not_to receive(:new)

        subject.call
      end
    end

    describe 'errors' do
      let(:exception) { WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: '501', message: 'Unsupported message type') }
      before do
        params[:messages] = [
          { errors: [{
            code: 501,
            details: 'Message type is not currently supported',
            title: 'Unsupported message type'
          }],
            from: '491511234567',
            id: 'some_valid_id',
            timestamp: '1691066820',
            type: 'unknown' }
        ]
        allow(ErrorNotifier).to receive(:report)
      end

      it 'reports the error' do
        expect(ErrorNotifier).to receive(:report).with(exception, context: { details: 'Message type is not currently supported' })

        subject.call
      end
    end

    describe 'unknown contributor' do
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
        create(:message, request: request, recipient: contributor)
      end

      context 'no message template sent' do
        it 'creates a messsage' do
          expect { subject.call }.to change(Message, :count).from(2).to(3)
        end
      end

      context 'responding to template' do
        before { contributor.update(whats_app_message_template_sent_at: Time.current) }
        let(:text) { latest_message }

        context 'request to receive latest message' do
          it 'enqueues a job to send the latest received message' do
            expect do
              subject.call
            end.to have_enqueued_job(WhatsAppAdapter::Outbound::ThreeSixtyDialogText).on_queue('default').with(text_payload)
          end

          it 'marks that contributor has responded to template message' do
            expect { subject.call }.to change {
                                         contributor.reload.whats_app_message_template_responded_at
                                       }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
          end
        end
      end

      context 'request for more info' do
        before { params[:messages].first[:text][:body] = 'Mehr Infos' }
        let(:text) { [Setting.about, "_#{I18n.t('adapter.whats_app.unsubscribe.instructions')}_"].join("\n\n") }

        it 'marks that contributor has responded to template message' do
          expect { subject.call }.to change {
                                       contributor.reload.whats_app_message_template_responded_at
                                     }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
        end

        it 'enqueues a job to send more info message' do
          expect do
            subject.call
          end.to have_enqueued_job(WhatsAppAdapter::Outbound::ThreeSixtyDialogText).on_queue('default').with(text_payload)
        end

        context 'does not enqueue a job' do
          let(:text) { latest_message }

          it 'to send the latest received message' do
            expect { subject.call }.not_to have_enqueued_job(WhatsAppAdapter::Outbound::ThreeSixtyDialogText).with(text_payload)
          end
        end
      end

      context 'request to unsubscribe' do
        let!(:admin) { create_list(:user, 2, admin: true) }
        let!(:non_admin_user) { create(:user) }

        before { params[:messages].first[:text][:body] = 'Abbestellen' }
        let(:text) do
          [I18n.t('adapter.whats_app.unsubscribe.successful'), "_#{I18n.t('adapter.whats_app.subscribe.instructions')}_"].join("\n\n")
        end

        it 'marks contributor as inactive' do
          expect { subject.call }.to change { contributor.reload.deactivated_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
        end

        it 'enqueues a job to inform the contributor of successful unsubscribe' do
          expect do
            subject.call
          end.to have_enqueued_job(WhatsAppAdapter::Outbound::ThreeSixtyDialogText).on_queue('default').with(text_payload)
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

        context 'does not enqueue a job' do
          let(:text) { latest_message }

          it 'to send the latest received message' do
            expect { subject.call }.not_to have_enqueued_job(WhatsAppAdapter::Outbound::ThreeSixtyDialogText).with(text_payload)
          end
        end
      end

      context 'request to re-subscribe' do
        let!(:admin) { create_list(:user, 2, admin: true) }
        let!(:non_admin_user) { create(:user) }

        before do
          contributor.update(deactivated_at: Time.current)
          params[:messages].first[:text][:body] = 'Bestellen'
        end

        let(:text) do
          I18n.t('adapter.whats_app.welcome_message', project_name: Setting.project_name)
        end

        it 'marks contributor as active' do
          expect { subject.call }.to change { contributor.reload.deactivated_at }.from(kind_of(ActiveSupport::TimeWithZone)).to(nil)
        end

        it 'marks that contributor has responded to template message' do
          expect { subject.call }.to change {
                                       contributor.reload.whats_app_message_template_responded_at
                                     }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
        end

        it 'enqueues a job to welcome contributor' do
          expect do
            subject.call
          end.to have_enqueued_job(WhatsAppAdapter::Outbound::ThreeSixtyDialogText).on_queue('default').with(text_payload)
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

        context 'does not enqueue a job' do
          let(:text) { latest_message }

          it 'to send the latest received message' do
            expect { subject.call }.not_to have_enqueued_job(WhatsAppAdapter::Outbound::ThreeSixtyDialogText).with(text_payload)
          end
        end

        # TODO: Write test cases for unsupported content
      end
    end
  end
end
