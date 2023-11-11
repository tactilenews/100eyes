# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnsubscribeContributorJob do
  describe '#perform_later(contributor_id, adapter)' do
    subject { -> { described_class.new.perform(contributor.id, adapter) } }

    context 'Signal contributor' do
      let(:adapter) { SignalAdapter::Outbound }

      it_behaves_like 'a Contributor unsubscribes', SignalAdapter::Outbound::Text do
        let(:contributor) { create(:contributor, signal_phone_number: '+491234567', signal_onboarding_completed_at: Time.current) }
      end
    end

    context 'Telegram contributor' do
      let(:adapter) { TelegramAdapter::Outbound }

      it_behaves_like 'a Contributor unsubscribes', TelegramAdapter::Outbound::Text do
        let(:contributor) { create(:contributor, telegram_id: 123_456_789) }
      end
    end

    context 'Threema contributor' do
      let(:adapter) { ThreemaAdapter::Outbound }
      let(:mock_threema_lookup) { Threema::Lookup.new(threema: Threema.new) }
      let(:threema_id) { 'Z1234567' }
      let(:valid_threema_id) { 'valid_public_key' }
      before do
        allow(Threema::Lookup).to receive(:new).and_return(mock_threema_lookup)
        allow(mock_threema_lookup).to receive(:key).with(threema_id).and_return(valid_threema_id)
      end

      it_behaves_like 'a Contributor unsubscribes', ThreemaAdapter::Outbound::Text do
        let(:contributor) { create(:contributor,  threema_id: threema_id) }
      end
    end

    context 'WhatsApp contributor' do
      let(:adapter) { WhatsAppAdapter::Outbound }

      it_behaves_like 'a Contributor unsubscribes', WhatsAppAdapter::Outbound::Text do
        let(:contributor) { create(:contributor,  whats_app_phone_number: '+491234567') }
      end
    end
  end
end
