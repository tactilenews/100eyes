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
        let(:unsubscribed_successfully_text) do
          [I18n.t('adapter.shared.unsubscribe.successful'), "_#{I18n.t('adapter.shared.subscribe.instructions')}_"].join("\n\n")
        end
        let(:admin) { create(:user, admin: true) }
        before do
          allow(Threema::Lookup).to receive(:new).with({ threema: threema }).and_return(threema_lookup_double)
          allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
        end

        it 'does not create a message' do
          expect { subject }.not_to change(Message, :count)
        end

        it 'deactivates the contributor' do
          Timecop.freeze(Time.zone.local(2008, 9, 1, 12, 0, 0)) do
            expect { subject }.to change { contributor.reload.deactivated_at }.from(nil).to(Time.current)
          end
        end

        it 'schedules an unsubscribed_successfully message' do
          expect { subject }.to have_enqueued_job(ThreemaAdapter::Outbound::Text) do |text, recipient|
            expect(text).to eq(unsubscribed_successfully_text)
            expect(recipient).to eq(contributor)
          end
        end

        it_behaves_like 'an ActivityNotification', 'ContributorMarkedInactive'

        it 'sends an email out to all admin' do
          expect { subject }.to have_enqueued_job.on_queue('default').with(
            'PostmarkAdapter::Outbound',
            'contributor_marked_as_inactive_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { admin: admin, contributor: contributor },
              args: []
            }
          )
        end
      end

      describe 'Re-subscribe' do
        let(:threema_mock) { instance_double(Threema::Receive::Text, content: 'Bestellen') }
        let(:admin) { create(:user, admin: true) }
        let(:deactivated_at) { Time.zone.local(2023, 0o4, 0o1) }

        before do
          allow(Threema::Lookup).to receive(:new).with({ threema: threema }).and_return(threema_lookup_double)
          allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
          allow(Setting).to receive(:onboarding_success_heading).and_return('Welcome!')
          allow(Setting).to receive(:onboarding_success_text).and_return('')
          contributor.update!(deactivated_at: deactivated_at)
        end

        it 'does not create a message' do
          expect { subject }.not_to change(Message, :count)
        end

        it 're-activates the contributor' do
          Timecop.freeze(Time.zone.local(2023, 0o4, 25)) do
            expect { subject }.to change { contributor.reload.deactivated_at }.from(deactivated_at).to(nil)
          end
        end

        it 'schedules a welcome message' do
          expect { subject }.to have_enqueued_job(ThreemaAdapter::Outbound::Text) do |text, recipient|
            expect(text).to eq('Welcome!/n')
            expect(recipient).to eq(contributor)
          end
        end

        it_behaves_like 'an ActivityNotification', 'ContributorSubscribed'

        it 'sends an email out to all admin' do
          expect { subject }.to have_enqueued_job.on_queue('default').with(
            'PostmarkAdapter::Outbound',
            'contributor_subscribed_email',
            'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
            {
              params: { admin: admin, contributor: contributor },
              args: []
            }
          )
        end
      end
    end
  end
end
