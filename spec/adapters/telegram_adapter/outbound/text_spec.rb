# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramAdapter::Outbound::Text do
  let(:adapter) { described_class.new }
  let(:contributor) { create(:contributor, telegram_id: 4) }
  let(:message) { create(:message, text: 'Forgot to ask: How are you?', broadcasted: true, recipient: contributor) }

  describe '#perform' do
    subject { adapter.perform(text: message.text, contributor_id: message.recipient.id) }
    let(:expected_message) { { chat_id: 4, text: 'Forgot to ask: How are you?', parse_mode: :HTML } }

    it 'sends the message with TelegramBot' do
      expect(Telegram.bot).to receive(:send_message).with(expected_message)

      subject
    end
  end
end
