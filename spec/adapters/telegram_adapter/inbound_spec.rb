# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe TelegramAdapter::Inbound, telegram_bot: :rails do
  before { Setting.telegram_contributor_not_found_message = 'Who are you?' }
  subject { -> { dispatch_message 'Hello Bot!', { from: { id: 'whoami' } } } }
  describe 'bounce!' do
    it { should_not(change { Message.count }) }
    it { should respond_with_message 'Who are you?' }
  end
end
