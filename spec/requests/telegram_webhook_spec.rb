# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe '#start!' do
    subject { -> { dispatch_command :start, { from: { username: 'Joe' } } } }
    it { should respond_with_message 'Hello Joe!' }
  end
end
