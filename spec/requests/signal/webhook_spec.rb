# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Signal::WebhookController do
  describe '#message' do
    subject { -> { post signal_webhook_path, params: params, as: :json } }

    let(:organization) { create(:organization, signal_server_phone_number: '+4915888315379') }
    let(:params) do
      {
        jsonrpc: '2.0',
        method: 'receive',
        params: signal_message
      }
    end
    let(:signal_message) do
      {
        account: organization.signal_server_phone_number,
        envelope: {
          source: 'a47f7b0a-c080-4f04-bcb2-b8c3e83c5f8e',
          sourceNumber: nil,
          sourceUuid: 'a47f7b0a-c080-4f04-bcb2-b8c3e83c5f8e',
          sourceName: 'John Doe',
          sourceDevice: 1,
          timestamp: 1_770_126_367_159,
          serverReceivedTimestamp: 1_770_126_367_487,
          serverDeliveredTimestamp: 1_770_126_367_490,
          dataMessage: {
            message: 'Hello',
            timestamp: 1_770_126_367_159
          }
        }
      }
    end

    before do
      allow(ErrorNotifier).to receive(:report)
    end

    it 'responds with 200 OK' do
      subject.call
      expect(response).to have_http_status(:ok)
    end

    it 'schedules a ProcessWebhookJob' do
      expect do
        subject.call
      end.to have_enqueued_job(SignalAdapter::ProcessWebhookJob).with(signal_message: signal_message)
    end

    describe 'invalid webhook with exception key' do
      let(:signal_message) do
        {
          exception: {
            type: 'InvalidMetadataMessageException',
            message: 'org.signal.libsignal.protocol.InvalidMessageException: protobuf encoding was invalid'
          },
          envelope: {
            source: nil,
            sourceNumber: nil,
            sourceUuid: nil,
            sourceName: nil,
            sourceDevice: nil,
            timestamp: 1_770_126_367_159,
            serverReceivedTimestamp: 1_770_126_367_487,
            serverDeliveredTimestamp: 1_770_126_367_490
          },
          account: organization.signal_server_phone_number
        }
      end

      it 'still responds with 200 OK' do
        subject.call
        expect(response).to have_http_status(:ok)
      end

      it 'still schedules a ProcessWebhookJob' do
        expect do
          subject.call
        end.to have_enqueued_job(SignalAdapter::ProcessWebhookJob).with(signal_message: signal_message)
      end

      it 'processes the job as an invalid message' do
        perform_enqueued_jobs { subject.call }
        expect(ErrorNotifier).to have_received(:report)
          .with(instance_of(SignalAdapter::InvalidMessageError))
      end
    end

    describe 'typing message webhook' do
      let(:signal_message) do
        {
          envelope: {
            source: 'a47f7b0a-c080-4f04-bcb2-b8c3e83c5f8e',
            sourceNumber: nil,
            sourceUuid: 'a47f7b0a-c080-4f04-bcb2-b8c3e83c5f8e',
            sourceName: '',
            sourceDevice: 1,
            timestamp: 1_770_126_361_027,
            serverReceivedTimestamp: 1_770_126_361_370,
            serverDeliveredTimestamp: 1_770_126_361_372,
            typingMessage: {
              action: 'STARTED',
              timestamp: 1_770_126_361_027
            }
          },
          account: organization.signal_server_phone_number
        }
      end

      it 'responds with 200 OK' do
        subject.call
        expect(response).to have_http_status(:ok)
      end

      it 'schedules a ProcessWebhookJob' do
        expect do
          subject.call
        end.to have_enqueued_job(SignalAdapter::ProcessWebhookJob).with(signal_message: signal_message)
      end

      it 'ignores the typing message in the job' do
        perform_enqueued_jobs
        expect(ErrorNotifier).not_to have_received(:report)
      end

      context 'with a data message present' do
        before do
          signal_message[:envelope][:dataMessage] = {
            message: 'Hello',
            timestamp: 1_770_126_361_027
          }
        end

        it 'processes the data message (not ignored)' do
          expect do
            subject.call
          end.to have_enqueued_job(SignalAdapter::ProcessWebhookJob).with(signal_message: signal_message)
        end
      end
    end

    describe 'webhook without method receive' do
      let(:params) do
        {
          jsonrpc: '2.0',
          method: 'listAccounts',
          params: {}
        }
      end

      it 'responds with 200 OK' do
        subject.call
        expect(response).to have_http_status(:ok)
      end

      it 'does not schedule a ProcessWebhookJob' do
        expect do
          subject.call
        end.not_to have_enqueued_job(SignalAdapter::ProcessWebhookJob)
      end
    end

    describe 'webhook with no params' do
      let(:params) do
        {
          jsonrpc: '2.0',
          method: 'receive'
        }
      end

      it 'responds with 200 OK' do
        subject.call
        expect(response).to have_http_status(:ok)
      end

      it 'does not schedule a ProcessWebhookJob' do
        expect do
          subject.call
        end.not_to have_enqueued_job(SignalAdapter::ProcessWebhookJob)
      end
    end

    describe 'malformed JSON' do
      subject { -> { post signal_webhook_path, params: '{ invalid json }', headers: { 'Content-Type' => 'application/json' } } }

      it 'responds with 200 OK' do
        subject.call
        expect(response).to have_http_status(:ok)
      end

      it 'does not schedule a ProcessWebhookJob' do
        expect do
          subject.call
        end.not_to have_enqueued_job(SignalAdapter::ProcessWebhookJob)
      end
    end
  end
end
