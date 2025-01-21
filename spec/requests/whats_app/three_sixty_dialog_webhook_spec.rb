# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WhatsApp::ThreeSixtyDialogWebhookController do
  describe '#messages' do
    subject { -> { post organization_whats_app_three_sixty_dialog_webhook_path(organization), params: params } }

    let(:organization) do
      create(:organization, whats_app_server_phone_number: '+4915133311445', three_sixty_dialog_client_api_key: 'valid_api_key')
    end
    let(:params) do
      { entry: [{ id: 'some_external_id',
                  changes: [{ value: {
                    messaging_product: 'whatsapp',
                    metadata: { display_phone_number: '4915133311445', phone_number_id: 'some_valid_id' },
                    contacts: [{ profile: { name: 'Matthew Rider' },
                                 wa_id: '491511234567' }],
                    messages: [{ from: '491511234567',
                                 id: 'some_valid_id',
                                 text: { body: 'Hey' },
                                 timestamp: '1692118778',
                                 type: 'text' }]
                  } }] }] }
    end
    let(:components) { params[:entry].first[:changes].first[:value] }
    let(:exception) { WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: error_code, message: error_message) }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'should be successful' do
      subject.call

      expect(response).to be_successful
    end

    it 'schedules a job to process the webhook' do
      expect do
        subject.call
      end.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::ProcessWebhookJob).with(organization_id: organization.id,
                                                                                          components: components)
    end

    describe 'statuses' do
      let(:message_delivery) do
        {
          'id' => 'valid_message_id',
          'status' => '',
          'timestamp' => '1732132030',
          'recipient_id' => '49123456789',
          'conversation' => {
            'id' => 'valid_conversation_id', 'origin' => {
              'type' => 'marketing'
            }
          },
          'pricing' => {
            'billable' => 'true', 'pricing_model' => 'CBP', 'category' => 'marketing'
          }
        }.with_indifferent_access
      end

      describe 'successful delivery' do
        context 'sent' do
          let(:sent_status) do
            message_delivery.merge(status: 'sent')
          end

          before { components[:statuses] = [sent_status] }

          it 'is successful' do
            subject.call
            expect(response).to be_successful
          end

          it 'schedules a job to process the messages statuses' do
            expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::ProcessMessageStatusJob).with(
              organization_id: organization.id,
              delivery_receipt: sent_status
            )
          end
        end

        context 'delivered' do
          let(:delivered_status) do
            message_delivery.merge({ status: 'delivered' })
          end

          before { components[:statuses] = [delivered_status] }

          it 'is successful' do
            subject.call
            expect(response).to be_successful
          end

          it 'schedules a job to process the messages statuses' do
            expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::ProcessMessageStatusJob).with(
              organization_id: organization.id,
              delivery_receipt: delivered_status
            )
          end
        end

        context 'read' do
          let(:read_status) do
            message_delivery.merge({ status: 'read' })
          end

          before { components[:statuses] = [read_status] }

          it 'is successful' do
            subject.call
            expect(response).to be_successful
          end

          it 'schedules a job to process the messages statuses' do
            expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::ProcessMessageStatusJob).with(
              organization_id: organization.id,
              delivery_receipt: read_status
            )
          end
        end
      end

      context 'unsuccessful delivery' do
        context 'failed delivery' do
          let(:user) { create(:user, organizations: [organization]) }
          context 'message undeliverable' do
            let(:failed_status) do
              [{
                id: 'valid_external_message_id',
                status: 'failed',
                timestamp: '1731672268',
                recipient_id: '49123456789',
                errors: [{
                  code: 131_026,
                  title: 'Message undeliverable',
                  message: 'Message undeliverable',
                  error_data: {
                    details: 'Message Undeliverable.'
                  }
                }]
              }]
            end
            let(:error_code) { 131_026 }
            let(:error_message) { 'Message undeliverable' }
            let!(:contributor) do
              create(:contributor, whats_app_phone_number: '+49123456789', organization: organization, email: nil, first_name: 'Johnny')
            end
            let(:message_explaining_reason_for_being_marked_inactive) do
              <<~HELLO
                Die Rufnummer wurde möglicherweise nicht bei WhatsApp registriert oder der Empfänger hat die neuen Nutzungsbedingungen und Datenschutzrichtlinien von WhatsApp nicht akzeptiert.
              HELLO
            end
            let(:message_continued) do
              <<~HELLO
                Es ist auch möglich, dass der Empfänger eine alte, nicht unterstützte Version des WhatsApp-Clients für sein Telefon verwendet. Bitte überprüfe dies mit Johnny
              HELLO
            end
            before { components[:statuses] = failed_status }

            it 'reports any errors' do
              expect(Sentry).to receive(:capture_exception).with(exception)

              subject.call
            end

            it 'marks the contributor as inactive since we are unable to send them a message' do
              subject.call
              expect(MarkInactiveContributorInactiveJob).to have_been_enqueued.with do |params|
                expect(params[:organization_id]).to eq(organization.id)
                expect(params[:contributor_id]).to eq(contributor.id)
              end
            end

            it 'displays a message to inform the contributor the potential reason' do
              perform_enqueued_jobs(only: MarkInactiveContributorInactiveJob) do
                subject.call
                get organization_contributor_path(organization, contributor, as: user)
                expect(page).to have_content(message_explaining_reason_for_being_marked_inactive.strip)
                expect(page).to have_content(message_continued.strip)
              end
            end
          end
        end
      end
    end

    describe 'errors' do
      let(:error_code) { 501 }
      let(:error_message) { 'Unsupported message type' }

      before do
        components[:errors] = [{
          code: 501,
          title: 'Unsupported message type',
          message: 'Unsupported message type',
          error_data: { details: 'Message type is not currently supported' }
        }]

        allow(ErrorNotifier).to receive(:report)
      end

      it 'reports the error' do
        context = { details: 'Message type is not currently supported', title: 'Unsupported message type' }
        expect(ErrorNotifier).to receive(:report).with(exception, context: context)

        subject.call
      end
    end
  end
end
