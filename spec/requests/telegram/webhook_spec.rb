# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe '#message' do
    subject { -> { dispatch_message 'Hello Bot!', { from: { id: 'whoami' } } } }

    context 'sending a message with a document' do
      before { Setting.telegram_unknown_content_message = "Cannot handle this, I'm sorry :(" }
      subject { -> { dispatch_message 'Hello Bot!', { from: { id: contributor.telegram_id }, document: 'something' } } }

      let(:contributor) { create(:contributor, telegram_id: 12_345) }

      it { should respond_with_message "Cannot handle this, I'm sorry :(" }
    end
  end
end
