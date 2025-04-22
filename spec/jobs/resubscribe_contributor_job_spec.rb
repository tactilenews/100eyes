# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResubscribeContributorJob do
  describe '#perform_later(contributor_id, adapter)' do
    let(:user) { create(:user, organizations: [organization]) }
    let(:organization) { create(:organization, project_name: 'Test Project') }

    subject { -> { described_class.new.perform(contributor.id, adapter) } }

    context 'unsubscribed Signal contributor' do
      let(:adapter) { SignalAdapter::Outbound }

      it_behaves_like 'a Contributor resubscribes', SignalAdapter::Outbound::Text do
        let(:contributor) do
          create(:contributor, :signal_contributor, signal_onboarding_completed_at: 1.week.ago, unsubscribed_at: 1.day.ago,
                                                    organization: organization)
        end
      end

      describe 'which has been marked inactive by a user' do
        it_behaves_like 'a resubscribe failure', SignalAdapter::Outbound::Text do
          let(:contributor) do
            create(:contributor,
                   :signal_contributor,
                   signal_onboarding_completed_at: 1.week.ago,
                   unsubscribed_at: 1.day.ago,
                   deactivated_at: Time.current,
                   deactivated_by_user: user,
                   organization: organization)
          end
        end
      end

      describe 'which has been marked inactive by an admin' do
        it_behaves_like 'a resubscribe failure', SignalAdapter::Outbound::Text do
          let(:contributor) do
            create(:contributor,
                   :signal_contributor_uuid,
                   signal_onboarding_completed_at: 1.week.ago,
                   unsubscribed_at: 1.day.ago,
                   deactivated_at: Time.current,
                   deactivated_by_admin: true,
                   organization: organization)
          end
        end
      end
    end

    context 'unsubscribed Telegram contributor' do
      let(:adapter) { TelegramAdapter::Outbound }

      it_behaves_like 'a Contributor resubscribes', TelegramAdapter::Outbound::Text do
        let(:contributor) { create(:contributor, telegram_id: 123_456_789, unsubscribed_at: 1.week.ago, organization: organization) }
      end

      describe 'which has been marked inactive by a user' do
        it_behaves_like 'a resubscribe failure', TelegramAdapter::Outbound::Text do
          let(:contributor) do
            create(:contributor,
                   telegram_id: 123_456_789,
                   unsubscribed_at: 1.week.ago,
                   deactivated_at: Time.current,
                   deactivated_by_user: user,
                   organization: organization)
          end
        end
      end

      describe 'which has been marked inactive by an admin' do
        it_behaves_like 'a resubscribe failure', TelegramAdapter::Outbound::Text do
          let(:contributor) do
            create(:contributor,
                   telegram_id: 123_456_789,
                   unsubscribed_at: 1.week.ago,
                   deactivated_at: Time.current,
                   deactivated_by_admin: true,
                   organization: organization)
          end
        end
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
        let(:contributor) do
          create(:contributor, threema_id: threema_id, unsubscribed_at: 1.month.ago,
                               organization: organization)
        end
      end

      describe 'which has been marked inactive by a user' do
        it_behaves_like 'a resubscribe failure', ThreemaAdapter::Outbound::Text do
          let(:contributor) do
            create(:contributor,
                   threema_id: threema_id,
                   unsubscribed_at: 1.month.ago,
                   deactivated_at: Time.current,
                   deactivated_by_user: user,
                   organization: organization)
          end
        end
      end

      describe 'which has been marked inactive by an admin' do
        it_behaves_like 'a resubscribe failure', ThreemaAdapter::Outbound::Text do
          let(:contributor) do
            create(:contributor,
                   threema_id: threema_id,
                   unsubscribed_at: 1.month.ago,
                   deactivated_at: Time.current,
                   deactivated_by_admin: true,
                   organization: organization)
          end
        end
      end
    end

    context 'unsubscribed WhatsApp contributor' do
      let(:adapter) { WhatsAppAdapter::ThreeSixtyDialogOutbound }

      before do
        organization.update!(three_sixty_dialog_client_api_key: 'valid_api_key')
      end

      it_behaves_like 'a Contributor resubscribes', WhatsAppAdapter::ThreeSixtyDialogOutbound::Text do
        let(:contributor) do
          create(:contributor, whats_app_phone_number: '+491234567', unsubscribed_at: 5.days.ago,
                               organization: organization)
        end
        let!(:resubscribe_message) do
          create(:message, sender: contributor, text: 'Bestellen')
        end
      end

      describe 'which has been marked inactive by a user' do
        it_behaves_like 'a resubscribe failure', WhatsAppAdapter::ThreeSixtyDialogOutbound::Text do
          let(:contributor) do
            create(:contributor,
                   whats_app_phone_number: '+491234567',
                   unsubscribed_at: 5.days.ago,
                   deactivated_at: Time.current,
                   deactivated_by_user: user,
                   organization: organization)
          end
        end
      end

      describe 'which has been marked inactive by an admin' do
        it_behaves_like 'a resubscribe failure', WhatsAppAdapter::ThreeSixtyDialogOutbound::Text do
          let(:contributor) do
            create(:contributor,
                   whats_app_phone_number: '+491234567',
                   unsubscribed_at: 5.days.ago,
                   deactivated_at: Time.current,
                   deactivated_by_admin: true,
                   organization: organization)
          end
        end
      end
    end
  end
end
