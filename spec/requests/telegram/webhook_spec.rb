# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe '#start!' do
    subject { -> { dispatch_command :start, { from: { username: 'Joe' } } } }
    it { should respond_with_message 'Hello Joe!' }
  end

  describe '#message' do
    subject { -> { dispatch_message 'Hello Bot!', { from: { telegram_id: 47, username: 'Joe' } } } }
    it { should change { User.count }.from(0).to(1) }
    describe 'created user' do
      before(:each) { subject.call }
      it { expect(User.first.telegram_id).to eq(47) }
    end
  end
end
