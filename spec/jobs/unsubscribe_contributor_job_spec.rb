# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnsubscribeContributorJob do
  describe '#perform_later(contributor_id, adapter)' do
    subject { -> { described_class.new.perform(organization.id, contributor.id, adapter) } }

    let(:organization) { create(:organization) }

    context 'given an unsubscribed contributor' do
      let(:contributor) do
        create(:contributor, whats_app_phone_number: '+491234567', unsubscribed_at: 1.day.ago, organization: organization)
      end
      let(:adapter) { WhatsAppAdapter::Delegator.new(organization) }

      it { is_expected.not_to(change { contributor.reload.unsubscribed_at }) }
    end

    context 'Signal contributor' do
      let(:adapter) { SignalAdapter::Outbound }

      it_behaves_like 'a Contributor unsubscribes', SignalAdapter::Outbound::Text do
        let(:contributor) do
          create(:contributor, signal_phone_number: '+491234567', signal_onboarding_completed_at: Time.current, organization: organization)
        end
      end
    end

    context 'Telegram contributor' do
      let(:adapter) { TelegramAdapter::Outbound }

      it_behaves_like 'a Contributor unsubscribes', TelegramAdapter::Outbound::Text do
        let(:contributor) { create(:contributor, telegram_id: 123_456_789, organization: organization) }
      end
    end

    context 'Threema contributor' do
      let(:adapter) { ThreemaAdapter::Outbound }
      let(:threema_lookup_double) { instance_double(Threema::Lookup) }
      let(:threema) { instance_double(Threema) }
      let(:threema_id) { 'Z1234567' }
      before do
        allow(Threema).to receive(:new).and_return(threema)
        allow(Threema::Lookup).to receive(:new).with({ threema: threema }).and_return(threema_lookup_double)
        allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
      end

      it_behaves_like 'a Contributor unsubscribes', ThreemaAdapter::Outbound::Text do
        let(:contributor) { create(:contributor, threema_id: threema_id, organization: organization) }
      end
    end

    context 'WhatsApp contributor' do
      context 'Twilio' do
        let(:adapter) { WhatsAppAdapter::TwilioOutbound }

        it_behaves_like 'a Contributor unsubscribes', WhatsAppAdapter::TwilioOutbound::Text do
          let(:contributor) { create(:contributor,  whats_app_phone_number: '+491234567', organization: organization) }
        end
      end

      context '360dialog' do
        let(:adapter) { WhatsAppAdapter::ThreeSixtyDialogOutbound }

        before { organization.update!(three_sixty_dialog_client_api_key: Faker::Internet.uuid) }

        it_behaves_like 'a Contributor unsubscribes', WhatsAppAdapter::ThreeSixtyDialogOutbound::Text do
          let(:contributor) { create(:contributor,  whats_app_phone_number: '+491234567', organization: organization) }
        end
      end
    end
  end
end
