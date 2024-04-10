# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramAdapter::Outbound do
  let(:message) { create(:message, text: 'Forgot to ask: How are you?', broadcasted: true, recipient: contributor) }
  let(:contributor) { create(:contributor, telegram_id: 4, email: nil) }

  describe '::send!' do
    subject { -> { described_class.send!(message) } }

    before { message } # we don't count the extra ::send here

    it { is_expected.to enqueue_job(described_class::Text) }

    context 'contributor has no telegram_id' do
      let(:contributor) { create(:contributor, telegram_id: nil, email: nil) }

      it { is_expected.not_to enqueue_job(described_class::Text) }
    end

    context 'contributor has telegram_onboarding_token' do
      let(:contributor) { create(:contributor, telegram_id: nil, telegram_onboarding_token: nil, email: nil) }

      it { is_expected.not_to enqueue_job(described_class::Text) }
    end

    context 'message has files attached' do
      before { message.reload }

      let(:message) { create(:message, :with_file, broadcasted: true, recipient: contributor) }

      it { is_expected.to enqueue_job(described_class::Photo) }
    end
  end

  describe '::send_welcome_message!' do
    subject { -> { described_class.send_welcome_message!(contributor) } }

    it { is_expected.to enqueue_job(described_class::Text) }

    context 'contributor has no telegram_id' do
      let(:contributor) { create(:contributor, telegram_id: nil, email: nil) }

      it { is_expected.not_to enqueue_job(described_class) }
    end
  end
end
