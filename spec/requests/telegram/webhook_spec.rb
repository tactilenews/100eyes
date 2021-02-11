# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe '#message' do
    context 'Unknown contributor' do
      subject { -> { dispatch_message 'Hello Bot!', { from: { id: 'whoami' } } } }

      it { is_expected.to respond_with_message Setting.telegram_contributor_not_found_message }

      describe 'Message received confirming onboarding' do
        subject { -> { dispatch_message 'Hello Bot!', { from: { id: 'whoami' }, connected_website: Setting.application_host } } }

        it { is_expected.not_to respond_with_message Setting.telegram_contributor_not_found_message }
      end
    end

    context 'sending a message with a document' do
      before { Setting.telegram_unknown_content_message = "Cannot handle this, I'm sorry :(" }
      subject { -> { dispatch_message 'Hello Bot!', { from: { id: contributor.telegram_id }, document: 'something' } } }

      let(:contributor) { create(:contributor, telegram_id: 12_345) }

      it { should respond_with_message "Cannot handle this, I'm sorry :(" }
    end
  end
end
