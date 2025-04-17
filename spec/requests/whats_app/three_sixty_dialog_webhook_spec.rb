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
        }.deep_transform_keys(&:to_sym)
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

            before { components[:statuses] = failed_status }

            it 'schedules a job to handle the failed delivery' do
              subject.call
              Delayed::Job.all.find do |job|
                handler = YAML.safe_load(job.handler)
                expect(handler.object).to eq(WhatsAppAdapter::HandleFailedMessageJob)
                expect(handler.args.first).to eq({ contributor_id: contributor.id, external_message_id: 'valid_external_message_id' })
              end
            end

            it 'delays the job for the future' do
              expect { subject.call }.to change(DelayedJob, :count).from(0).to(1)
              expect(Delayed::Job.last.run_at).to be_within(1.second).of(Time.current.tomorrow.beginning_of_day)
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
