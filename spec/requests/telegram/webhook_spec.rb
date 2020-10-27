# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe '#start!' do
    subject { -> { dispatch_command :start, { from: { username: 'Joe' } } } }
    it { should respond_with_message I18n.t('telegram.welcome_message') }
  end

  describe '#message' do
    subject { -> { dispatch_message 'Hello Bot!', { from: { id: 47, username: 'Joe' } } } }
    it { should change { User.count }.from(0).to(1) }
    describe 'created user' do
      before(:each) { subject.call }
      it { expect(User.first.telegram_id).to eq(47) }
    end

    describe 'sending a message with a document' do
      subject { -> { dispatch_message 'Hello Bot!', { from: { id: 47, username: 'Joe' }, document: 'something' } } }
      it { should respond_with_message I18n.t('telegram.unknown_content_message') }
    end
  end
end
