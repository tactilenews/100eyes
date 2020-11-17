# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe '#start!' do
    before do
      Setting.telegram_who_are_you_message = 'Who are you?'
    end

    context 'has onboarded' do
      let(:contributor) { create(:contributor, telegram_id: 12_345) }
      subject { -> { dispatch_command :start, { from: { id: contributor.telegram_id } } } }
      it { should_not respond_with_message 'Who are you?' }
    end

    context 'contributor has not onboarded yet' do
      subject { -> { dispatch_command :start, { from: { id: 'whoami' } } } }
      it { should respond_with_message 'Who are you?' }
    end
  end

  describe '#message' do
    before { Setting.telegram_who_are_you_message = 'Who are you?' }
    subject { -> { dispatch_message 'Hello Bot!', { from: { id: 'whoami' } } } }

    context 'contributor has not onboarded yet' do
      it { should respond_with_message 'Who are you?' }
      it { should_not change(Contributor, :count) }
    end

    context 'sending a message with a document' do
      before { Setting.telegram_unknown_content_message = "Cannot handle this, I'm sorry :(" }
      subject { -> { dispatch_message 'Hello Bot!', { from: { id: contributor.telegram_id }, document: 'something' } } }

      let(:contributor) { create(:contributor, telegram_id: 12_345) }

      it { should respond_with_message "Cannot handle this, I'm sorry :(" }
    end
  end
end
