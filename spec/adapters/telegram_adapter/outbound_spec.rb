# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramAdapter::Outbound do
  let(:adapter) { described_class.new }
  let(:message) { create(:message, text: 'Forgot to ask: How are you?', broadcasted: true, recipient: contributor) }
  let(:contributor) { create(:contributor, telegram_id: 4) }
  let(:onboarding_success_heading_record) { Setting.new(var: :onboarding_success_heading) }
  let(:onboarding_success_text_record) { Setting.new(var: :onboarding_success_text) }

  describe '::send!' do
    before { message } # we don't count the extra ::send here
    subject { -> { described_class.send!(message) } }
    it { should enqueue_job(described_class) }

    context 'contributor has no telegram_id' do
      let(:contributor) { create(:contributor, telegram_id: nil, email: nil) }
      it { should_not enqueue_job(described_class) }
    end

    context 'contributor has telegram_onboarding_token' do
      let(:contributor) { create(:contributor, telegram_id: nil, telegram_onboarding_token: nil, email: nil) }
      it { should_not enqueue_job(described_class) }
    end
  end

  describe '::send_welcome_message!' do
    subject { -> { described_class.send_welcome_message!(contributor) } }

    before do
      allow(Setting).to receive(:find_by).with(var: :onboarding_success_heading).and_return(onboarding_success_heading_record)
      allow(onboarding_success_heading_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('Welcome new contributor!')
      allow(Setting).to receive(:find_by).with(var: :onboarding_success_text).and_return(onboarding_success_text_record)
      allow(onboarding_success_text_record).to receive(:send).with("value_#{I18n.locale}".to_sym).and_return('You onboarded successfully.')
    end

    it { should enqueue_job(described_class) }
    context 'contributor has no telegram_id' do
      let(:contributor) { create(:contributor, telegram_id: nil, email: nil) }
      it { should_not enqueue_job(described_class) }
    end
  end

  describe '#perform' do
    subject { adapter.perform(text: message.text, recipient: message.recipient) }
    let(:expected_message) { { chat_id: 4, text: 'Forgot to ask: How are you?', parse_mode: :HTML } }

    it 'sends the message with TelegramBot' do
      expect(Telegram.bot).to receive(:send_message).with(expected_message)

      subject
    end
  end
end
