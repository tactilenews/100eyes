# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramAdapter::Outbound do
  let(:adapter) { described_class.new }

  describe '#perform' do
    subject { adapter.perform(text: message.text, recipient: message.recipient) }
    let(:message) { create(:message, text: 'Forgot to ask: How are you?', broadcasted: true, recipient: contributor) }
    let(:contributor) { create(:contributor, telegram_id: 4) }
    let(:expected_message) { { chat_id: 4, text: 'Forgot to ask: How are you?', parse_mode: :HTML } }

    describe '::send!' do
      before { message } # we don't count the extra ::send here
      subject { -> { described_class.send!(message) } }
      it { should enqueue_job(described_class) }
      context 'contributor has no telegram_id' do
        let(:contributor) { create(:contributor, telegram_id: nil, email: nil) }
        it { should_not enqueue_job(described_class) }
      end
    end

    describe '::send_welcome_message!' do
      subject { -> { described_class.send_welcome_message!(contributor) } }
      it { should enqueue_job(described_class) }
      context 'contributor has no telegram_id' do
        let(:contributor) { create(:contributor, telegram_id: nil, email: nil) }
        it { should_not enqueue_job(described_class) }
      end
    end

    it 'sends the message with TelegramBot' do
      expect(Telegram.bot).to receive(:send_message).with(expected_message)

      subject
    end
  end
end
