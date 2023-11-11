# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  before do
    allow(Setting).to receive(:telegram_contributor_not_found_message).and_return('Who are you?')
    allow(Setting).to receive(:telegram_unknown_content_message).and_return("Cannot handle this, I'm sorry :(")
    allow(Setting).to receive(:onboarding_success_heading).and_return('Welcome new contributor!')
    allow(Setting).to receive(:onboarding_success_text).and_return('')
  end

  describe '#start!' do
    let(:message) { '/start' }
    let(:chat_id) { 9876 }
    let(:message_options) { { from: { id: chat_id } } }
    subject { -> { perform_enqueued_jobs { dispatch_message message, message_options } } }
    it { should_not(change { Message.count }) }
    it { should respond_with_message 'Who are you?' }

    context 'given a contributor' do
      before { contributor }

      context 'who just signed up' do
        let(:contributor) { create(:contributor, :with_an_avatar, telegram_id: nil, telegram_onboarding_token: 'ABCDEF') }
        it { should respond_with_message 'Who are you?' }
        it { should_not(change { Message.count }) }
        context 'and sends the right telegram_onboarding_token' do
          let(:message) { '/start ABCDEF' }
          it { should respond_with_message "<b>Welcome new contributor!</b>\n" }
          it { should(change { Contributor.first.telegram_id }.from(nil).to(9876)) }
        end
      end

      context 'who is already connected but not the person sending the telegram message' do
        let(:contributor) { create(:contributor, :with_an_avatar, telegram_id: 9876, telegram_onboarding_token: 'ABCDEF') }
        let(:message_options) { { from: { id: 9877 } } }
        it { should respond_with_message 'Who are you?' }
        it { should_not(change { Contributor.first.telegram_id }) }
      end

      context 'with a matching `telegram_id`' do
        let(:contributor) { create(:contributor, :with_an_avatar, telegram_id: 9876) }
        it { should respond_with_message "<b>Welcome new contributor!</b>\n" }
        it { should_not(change(Contributor, :count)) }

        context 'given a recent request' do
          let(:request) { create(:request) }
          before { request }
          it { should_not(change { Message.count }) }

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
            it { should(change { Message.count }.from(0).to(1)) }
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
        let(:contributor) { create(:contributor, :with_an_avatar, telegram_id: nil, telegram_onboarding_token: 'GHIJKL') }
        it { should respond_with_message 'Who are you?' }

        context 'and sends telegram_onboarding_token' do
          let(:message) { " \n  GHIJKL  \t " }
          it { should respond_with_message "<b>Welcome new contributor!</b>\n" }
          it { should(change { contributor.reload.telegram_id }.from(nil).to(12_345)) }

          describe 'treats message case-insensitive' do
            let(:message) { " \n  GhIjKl  \t " }
            it { should respond_with_message "<b>Welcome new contributor!</b>\n" }
            it { should(change { contributor.reload.telegram_id }.from(nil).to(12_345)) }
          end

          context 'even if other contributors are not connected yet' do
            before { other_contributor }
            let(:other_contributor) { create(:contributor, :with_an_avatar, telegram_id: nil, telegram_onboarding_token: 'XYZXYZ') }
            it { should(change { contributor.reload.telegram_id }.from(nil).to(12_345)) }
            it { should_not(change { other_contributor.reload.telegram_id }) }
          end
        end
      end

      context 'who is already connected' do
        subject { -> { dispatch_message message, message_options } }
        let(:contributor) { create(:contributor, :with_an_avatar, telegram_id: 12_345) }

        it { should_not(change { Message.count }) }

        context 'given a recent request' do
          before { create(:request) }
          it { should(change { Message.count }.from(0).to(1)) }
          it { should_not respond_with_message }
          it_behaves_like 'an ActivityNotification', 'MessageReceived'
        end

        context ' message has a document' do
          let(:message_options) { { from: { id: 12_345 }, document: 'something' } }
          it { should respond_with_message "Cannot handle this, I'm sorry :(" }
        end

        context 'who would like to unsubscribe' do
          let(:message) { 'Abbestellen' }
          let(:chat_id) { 123_456_789 }

          it_behaves_like 'a Contributor unsubscribes', :with_an_avatar, { telegram_id: 123_456_789 }, TelegramAdapter::Outbound::Text
        end

        context 'who has unsubsribed, and would like to re-subscribe' do
          let(:message) { 'Bestellen' }
          let(:admin) { create(:user, admin: true) }
          let(:unsubscribed_at) { Time.zone.local(2023, 0o4, 0o1) }

          before do
            allow(Setting).to receive(:onboarding_success_heading).and_return('Welcome!')
            allow(Setting).to receive(:onboarding_success_text).and_return('')
            contributor.update!(unsubscribed_at: unsubscribed_at)
          end

          it 'does not create a message' do
            expect { subject.call }.not_to change(Message, :count)
          end

          it 're-activates the contributor' do
            expect { subject.call }.to change { contributor.reload.unsubscribed_at }.from(unsubscribed_at).to(nil)
          end

          it 'schedules a welcome message' do
            expect { subject.call }.to have_enqueued_job(TelegramAdapter::Outbound::Text) do |text, telegram_id|
              expect(text).to eq('Welcome!/n')
              expect(telegram_id).to eq(contributor.telegram_id)
            end
          end

          it_behaves_like 'an ActivityNotification', 'ContributorSubscribed'

          it 'sends an email out to all admin' do
            expect { subject.call }.to have_enqueued_job.on_queue('default').with(
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
end
