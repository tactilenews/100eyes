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
  let!(:organization) { create(:organization, threemarb_api_identity: '*100EYES', users_count: 1) }
  let!(:admin) { create_list(:user, 2, admin: true) }
  let!(:user) { create(:user, organizations: [organization]) }

  before do
    allow(Threema).to receive(:new).and_return(threema)
    allow(threema).to receive(:receive).and_return(threema_mock)
    allow(client_mock).to receive(:not_found_ok)
    allow(threema).to receive(:client).and_return(client_mock)
    allow(threema_mock).to receive(:instance_of?) { false }
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
      let!(:contributor) { create(:contributor, :skip_validations, threema_id: 'V5EA564T', organization: organization) }
      let!(:request) { create(:request, organization: organization, user: user) }

      before do
        allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::Text).and_return(true)
      end

      it { is_expected.to eq(200) }

      it 'creates a message' do
        expect { subject }.to change(Message, :count).from(0).to(1)
      end

      it_behaves_like 'an ActivityNotification', 'MessageReceived', 4

      describe 'DeliveryReceipt' do
        let(:threema_mock) do
          instance_double(
            Threema::Receive::DeliveryReceipt, content: 'x\00x\\0', message_ids: message_ids, status: status, timestamp: timestamp
          )
        end
        let(:messages) { [create(:message, external_id: SecureRandom.alphanumeric(16), organization: organization)] }
        let(:message_ids) { messages.pluck(:external_id) }
        let(:status) { :received }
        let(:timestamp) { Time.current.to_i }
        before { allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::DeliveryReceipt).and_return(true) }

        it 'returns 200 to avoid retries' do
          subject
          expect(response).to have_http_status(200)
        end

        context 'given a received status for a known message' do
          it 'updates the delivered_at attr' do
            expect { subject }.to change { messages.first.reload.delivered_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
          end
        end

        context 'given a read status for a known message' do
          let(:status) { :read }

          it 'updates the read_at attr' do
            expect { subject }.to change { messages.first.reload.read_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
          end

          it 'updates receive_at if blank' do
            expect { subject }.to change { messages.first.reload.delivered_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
          end
        end

        context 'given multiple message_ids' do
          let(:messages) { create_list(:message, 3, external_id: SecureRandom.alphanumeric(16), organization: organization) }
          let(:other_message) { create(:message, external_id: SecureRandom.alphanumeric(16)) }
          let(:message_ids) { messages.pluck(:external_id) << other_message.id }
          let(:status) { :read }

          it 'updates all messages belonging to the organization' do
            expect { subject }.to change { messages.first.reload.read_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone)).and \
              change { messages.second.reload.read_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone)).and \
                change { messages.third.reload.read_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
          end

          it 'doesn\'t update the other message' do
            expect { subject }.not_to(change { other_message.reload.read_at })
          end
        end
      end

      describe 'Threema::Receive::File' do
        let(:audio_content) do
          "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01"
        end
        let(:threema_mock) do
          instance_double(Threema::Receive::File, content: audio_content, mime_type: 'audio/mp4', name: 'some audio file', caption: nil)
        end

        before do
          allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::Text).and_return(false)
          allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::File).and_return(true)
        end

        it { is_expected.to eq(200) }

        it 'creates a message' do
          expect { subject }.to change(Message, :count).from(0).to(1)
        end

        it_behaves_like 'an ActivityNotification', 'MessageReceived', 4
      end

      describe 'Unsupported content' do
        let(:threema_mock) { instance_double(Threema::Receive::NotImplementedFallback, content: 'x\00x\\0') }

        before do
          allow(threema_mock).to receive(:instance_of?).with(Threema::Receive::NotImplementedFallback).and_return(true)
          allow(threema_mock).to receive(:respond_to?).with(:mime_type).and_return(true)
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
          expect { subject }.to have_enqueued_job(UnsubscribeContributorJob).with(organization.id, contributor.id, ThreemaAdapter::Outbound)
        end
      end

      describe 'Re-subscribe' do
        let(:threema_mock) { instance_double(Threema::Receive::Text, content: 'Bestellen') }
        before do
          contributor.unsubscribed_at = 1.day.ago
          contributor.save(validate: false)
        end

        it 'enqueues a job to resubscribe the contributor' do
          expect { subject }.to have_enqueued_job(ResubscribeContributorJob).with(organization.id, contributor.id, ThreemaAdapter::Outbound)
        end
      end
    end
  end
end
