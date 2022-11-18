# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramAdapter::Outbound do
  let(:message) { create(:message, text: 'Forgot to ask: How are you?', broadcasted: true, recipient: contributor) }
  let(:contributor) { create(:contributor, telegram_id: 4) }

  describe '::send!' do
    before { message } # we don't count the extra ::send here
    subject { -> { described_class.send!(message) } }

    it { should enqueue_job(described_class::Text) }

    context 'contributor has no telegram_id' do
      let(:contributor) { create(:contributor, telegram_id: nil, email: nil) }
      it { should_not enqueue_job(described_class::Text) }
    end

    context 'contributor has telegram_onboarding_token' do
      let(:contributor) { create(:contributor, telegram_id: nil, telegram_onboarding_token: nil, email: nil) }
      it { should_not enqueue_job(described_class::Text) }
    end
  end

  describe '::send_welcome_message!' do
    subject { -> { described_class.send_welcome_message!(contributor) } }
    it { should enqueue_job(described_class::Text) }
    context 'contributor has no telegram_id' do
      let(:contributor) { create(:contributor, telegram_id: nil, email: nil) }
      it { should_not enqueue_job(described_class) }
    end
  end
end
