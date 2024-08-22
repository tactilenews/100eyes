# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  let(:organization) do
    create(
      :organization,
      name: '100eyes',
      telegram_bot_api_key: 'TELEGRAM_BOT_API_KEY',
      telegram_bot_username: 'USERNAME',
      telegram_contributor_not_found_message: 'Who are you?',
      telegram_unknown_content_message: 'Cannot handle this, I\'m sorry :(',
      onboarding_success_heading: 'Welcome new contributor!',
      onboarding_success_text: '',
      users_count: 1
    )
  end
  let!(:admin) { create_list(:user, 2, admin: true) }
  let!(:user) { create(:user, organizations: [organization]) }
  let(:bot) { organization.telegram_bot }
  let(:controller_path) do
    "/telegram/#{Telegram::Bot::RoutesHelper.token_hash(organization.telegram_bot_api_key)}"
  end

  before do
    Telegram.reset_bots
    Telegram.bots_config = {
      organization.id => { token: organization.telegram_bot_api_key, username: organization.telegram_bot_username }
    }
    Rails.application.reload_routes!
  end

  describe '#start!' do
    let(:message) { '/start' }
    let(:chat_id) { 9876 }
    let(:message_options) { { from: { id: chat_id } } }
    subject { -> { perform_enqueued_jobs { dispatch_message message, message_options } } }
    it { expect { subject.call }.not_to(change { Message.count }) }
    it { expect { subject.call }.to respond_with_message 'Who are you?' }

    context 'given a contributor' do
      before do
        organization.reload
        organization.contributors.reload
        contributor
      end

      context 'who just signed up' do
        let(:contributor) do
          create(:contributor, :with_an_avatar, telegram_id: nil, telegram_onboarding_token: 'ABCDEF', organization: organization)
        end
        it { expect { subject.call }.to respond_with_message 'Who are you?' }
        it { expect { subject.call }.not_to(change { Message.count }) }
        context 'and sends the right telegram_onboarding_token' do
          let(:message) { '/start ABCDEF' }
          it { expect { subject.call }.to respond_with_message "<b>Welcome new contributor!</b>\n" }
          it { expect { subject.call }.to(change { Contributor.first.telegram_id }.from(nil).to(9876)) }
        end
      end

      context 'who is already connected but not the person sending the telegram message' do
        let(:contributor) do
          create(:contributor, :with_an_avatar, telegram_id: 9876, telegram_onboarding_token: 'ABCDEF', organization: organization)
        end
        let(:message_options) { { from: { id: 9877 } } }
        it { expect { subject.call }.to respond_with_message 'Who are you?' }
        it { expect { subject.call }.not_to(change { Contributor.first.telegram_id }) }
      end

      context 'with a matching `telegram_id`' do
        let(:contributor) { create(:contributor, :with_an_avatar, telegram_id: 9876, organization: organization) }
        it { expect { subject.call }.to respond_with_message "<b>Welcome new contributor!</b>\n" }
        it { expect { subject.call }.not_to(change(Contributor, :count)) }

        context 'given a recent request' do
          let(:request) { create(:request) }
          before { request }
          it { expect { subject.call }.not_to(change { Message.count }) }

          context 'sanity check' do
            let(:message) do
              [
                'This is not a command, therefore it should not be handled by',
                'the `start!` controller action but the `message` action',
                'instead. We can observe this in a test by checking that a',
                '`Message` record was saved. The behaviour is desired because',
                'any command e.g. /start should not be considered a response,',
                'only a written message like this.'
              ].join(' ')
            end
            it { expect { subject.call }.to(change { Message.count }.from(0).to(1)) }
          end
        end
      end
    end
  end

  describe '#message' do
    let(:message) { 'Hello Bot!' }
    let(:message_options) { { from: { id: 'whoami' } } }
    subject { -> { perform_enqueued_jobs { dispatch_message message, message_options } } }
    it { is_expected.to respond_with_message 'Who are you?' }

    context 'from a contributor' do
      before { contributor }
      let(:chat_id) { 12_345 }
      let(:message_options) { { from: { id: chat_id } } }

      context 'who just signed up' do
        let(:contributor) do
          create(:contributor, :with_an_avatar, telegram_id: nil, telegram_onboarding_token: 'GHIJKL', organization: organization)
        end
        it { expect { subject.call }.to respond_with_message 'Who are you?' }

        context 'and sends telegram_onboarding_token' do
          let(:message) { " \n  GHIJKL  \t " }
          it { expect { subject.call }.to respond_with_message "<b>Welcome new contributor!</b>\n" }
          it { expect { subject.call }.to(change { contributor.reload.telegram_id }.from(nil).to(12_345)) }

          describe 'treats message case-insensitive' do
            let(:message) { " \n  GhIjKl  \t " }
            it { expect { subject.call }.to respond_with_message "<b>Welcome new contributor!</b>\n" }
            it { expect { subject.call }.to(change { contributor.reload.telegram_id }.from(nil).to(12_345)) }
          end

          context 'even if other contributors are not connected yet' do
            before { other_contributor }
            let(:other_contributor) { create(:contributor, :with_an_avatar, telegram_id: nil, telegram_onboarding_token: 'XYZXYZ') }
            it { expect { subject.call }.to(change { contributor.reload.telegram_id }.from(nil).to(12_345)) }
            it { expect { subject.call }.not_to(change { other_contributor.reload.telegram_id }) }
          end
        end
      end

      context 'who is already connected' do
        subject { -> { dispatch_message message, message_options } }
        let(:contributor) { create(:contributor, :with_an_avatar, telegram_id: 12_345, organization: organization) }

        it { expect { subject.call }.not_to(change { Message.count }) }

        context 'given a recent request' do
          before { create(:request, organization: organization, user: user) }
          it { expect { subject.call }.to(change { Message.count }.from(0).to(1)) }
          it { expect { subject.call }.not_to respond_with_message }
          it_behaves_like 'an ActivityNotification', 'MessageReceived', 4
        end

        context ' message has a document' do
          let(:message_options) { { from: { id: 12_345 }, document: 'something' } }
          it { expect { subject.call }.to respond_with_message "Cannot handle this, I'm sorry :(" }
        end

        context 'who would like to unsubscribe' do
          let(:message) { 'Abbestellen' }

          it {
            is_expected.to have_enqueued_job(UnsubscribeContributorJob).with(organization.id, contributor.id, TelegramAdapter::Outbound)
          }
        end

        context 'who has unsubsribed, and would like to re-subscribe' do
          let(:message) { 'Bestellen' }
          before { contributor.update!(unsubscribed_at: 1.day.ago) }

          it {
            is_expected.to have_enqueued_job(ResubscribeContributorJob).with(organization.id, contributor.id, TelegramAdapter::Outbound)
          }
        end
      end
    end
  end
end
