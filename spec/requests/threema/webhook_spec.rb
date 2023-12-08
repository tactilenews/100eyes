# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Threema::WebhookController do
  let(:params) do
    {
      'from' => 'V5EA564T',
      'to' => '*100EYES',
      'messageId' => 'dfbe859c44f15125',
      'date' => '1612808574',
      'nonce' => 'b1c80cf818e289e6b1966b9bcab6fb9fb5e31862b46d8f98',
      'box' => 'ENCRYPTED FILE',
      'mac' => '8c58e9d4d9ad1aa960a58a1f11bcf712e9fcd50319778762824d8259dcbdc639',
      'nickname' => 'matt.rider'
    }
  end
  let(:threema_mock) { instance_double(Threema::Receive::Text, content: 'Hello World!') }
  let(:threema) { instance_double(Threema) }
  let(:client_mock) { instance_double(Threema::Client) }
  let(:threema_lookup_double) { instance_double(Threema::Lookup) }

  before do
    allow(Threema).to receive(:new).and_return(threema)
    allow(threema).to receive(:receive).and_return(threema_mock)
    allow(client_mock).to receive(:not_found_ok)
    allow(threema).to receive(:client).and_return(client_mock)
  end

  describe '#message' do
    subject { post '/threema/webhook', params: params }

    context 'No contributor' do
      before { allow(Sentry).to receive(:capture_exception).with(an_instance_of(ThreemaAdapter::UnknownContributorError)) }

      it 'does not create a message' do
        expect { subject }.not_to change(Message, :count)
      end

      it 'sends an error to Sentry so that our admins get notified' do
        subject
        expect(Sentry).to have_received(:capture_exception)
      end
    end

    context 'With known contributor' do
      let!(:contributor) { build(:contributor, threema_id: 'V5EA564T').tap { |contributor| contributor.save(validate: false) } }
      let!(:request) { create(:request) }

      before do
        allow(threema_mock).to receive(:instance_of?) { false }
      end

      it { is_expected.to eq(200) }

      it 'creates a message' do
        expect { subject }.to change(Message, :count).from(0).to(1)
      end

      it_behaves_like 'an ActivityNotification', 'MessageReceived'

      describe 'DeliveryReceipt' do
        let(:threema_mock) { instance_double(Threema::Receive::DeliveryReceipt, content: 'x\00x\\0') }
        before { allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::DeliveryReceipt).and_return(true) }

        it 'returns 200 to avoid retries' do
          subject
          expect(response).to have_http_status(200)
        end
      end

      describe 'Threema::Receive::File' do
        let(:audio_content) do
          "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01"
        end
        let(:threema_mock) do
          instance_double(Threema::Receive::File, content: audio_content, mime_type: 'audio/mp4', name: 'some audio file', caption: nil)
        end

        before { allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::File).and_return(true) }

        it { is_expected.to eq(200) }

        it 'creates a message' do
          expect { subject }.to change(Message, :count).from(0).to(1)
        end

        it_behaves_like 'an ActivityNotification', 'MessageReceived'
      end

      describe 'Unsupported content' do
        let(:threema_mock) { instance_double(Threema::Receive::NotImplementedFallback, content: 'x\00x\\0') }

        before do
          allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::NotImplementedFallback).and_return(true)
          allow(threema_mock).to receive(:respond_to?).with(:mime_type).and_return(true)
          allow(Setting).to receive(:threema_unknown_content_message).and_return('Oh no, this is unsupported!')
        end

        it 'returns 200 to avoid retries' do
          subject
          expect(response).to have_http_status(200)
        end

        it 'sends an automated message response' do
          expect { subject }.to have_enqueued_job(ThreemaAdapter::Outbound::Text).with do |text, recipient|
            expect(text).to eq('Oh, no, this is unsuporrted!')
            expect(recipient).to eq(contributor)
          end
        end
      end

      describe 'Unsubscribe' do
        let(:threema_mock) { instance_double(Threema::Receive::Text, content: 'Abbestellen') }

        it 'enqueues a job to unsubscribe the contributor' do
          expect { subject }.to have_enqueued_job(UnsubscribeContributorJob).with(contributor.id, ThreemaAdapter::Outbound)
        end
      end

      describe 'Re-subscribe' do
        let(:threema_mock) { instance_double(Threema::Receive::Text, content: 'Bestellen') }
        before do
          contributor.unsubscribed_at = 1.day.ago
          contributor.save(validate: false)
        end

        it 'enqueues a job to resubscribe the contributor' do
          expect { subject }.to have_enqueued_job(ResubscribeContributorJob).with(contributor.id, ThreemaAdapter::Outbound)
        end
      end
    end
  end
end
