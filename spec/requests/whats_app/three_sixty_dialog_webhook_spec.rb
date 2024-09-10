# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WhatsApp::ThreeSixtyDialogWebhookController do
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

  subject { -> { post organization_whats_app_three_sixty_dialog_webhook_path(organization), params: params } }

  describe '#messages' do
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
      let(:params) do
        {
          statuses: [{ id: 'some_valid_id',
                       message: { recipient_id: '491511234567' },
                       status: 'read',
                       timestamp: '1691405467',
                       type: 'message' }]
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
        components[:errors] = [{
          code: 501,
          title: 'Unsupported message type',
          error_data: { details: 'Message type is not currently supported' }
        }]

        allow(ErrorNotifier).to receive(:report)
      end

      it 'reports the error' do
        expect(ErrorNotifier).to receive(:report).with(exception, context: { details: 'Message type is not currently supported' })

        subject.call
      end
    end
  end
end
