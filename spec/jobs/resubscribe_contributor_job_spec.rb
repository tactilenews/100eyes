# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResubscribeContributorJob do
  describe '#perform_later(contributor_id, adapter)' do
    let(:user) { create(:user) }

    subject { -> { described_class.new.perform(contributor.id, adapter) } }

    context 'unsubscribed Signal contributor' do
      let(:adapter) { SignalAdapter::Outbound }

      it_behaves_like 'a Contributor resubscribes', SignalAdapter::Outbound::Text do
        let(:contributor) { create(:contributor, signal_phone_number: '+491234567', signal_onboarding_completed_at: Time.current, unsubscribed_at: 1.day.ago) }
      end
    end

    context 'unsubscribed Telegram contributor' do
      let(:adapter) { TelegramAdapter::Outbound }

      it_behaves_like 'a Contributor resubscribes', TelegramAdapter::Outbound::Text do
        let(:contributor) { create(:contributor, telegram_id: 123_456_789, unsubscribed_at: 1.week.ago) }
      end
    end

    context 'unsubscribed Threema contributor' do
      let(:adapter) { ThreemaAdapter::Outbound }
      let(:threema_lookup_double) { instance_double(Threema::Lookup) }
      let(:threema) { instance_double(Threema) }
      let(:threema_id) { 'Z1234567' }
      before do
        allow(Threema).to receive(:new).and_return(threema)
        allow(Threema::Lookup).to receive(:new).with({ threema: threema }).and_return(threema_lookup_double)
        allow(threema_lookup_double).to receive(:key).and_return('PUBLIC_KEY_HEX_ENCODED')
      end

      it_behaves_like 'a Contributor resubscribes', ThreemaAdapter::Outbound::Text do
        let(:contributor) { create(:contributor,  threema_id: threema_id, unsubscribed_at: 1.month.ago) }
      end
    end

    context 'unsubscribed WhatsApp contributor' do
      let(:adapter) { WhatsAppAdapter::Outbound }
      let(:whats_app_welcome_template) { I18n.t('adapter.whats_app.welcome_message').gsub('%{project_name}', '100eyes') }
      before do
        allow(Setting).to receive(:onboarding_success_text).and_return(whats_app_welcome_template)
      end

      it_behaves_like 'a Contributor resubscribes', WhatsAppAdapter::Outbound::Text do
        let(:contributor) { create(:contributor,  whats_app_phone_number: '+491234567', unsubscribed_at: 5.days.ago) }
      end
    end
  end
end
