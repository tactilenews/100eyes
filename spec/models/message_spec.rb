# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  it 'is by default sorted in reverse chronological order' do
    oldest_message = create(:message, created_at: 2.hours.ago)
    newest_message = create(:message, created_at: 1.hour.ago)

    expect(described_class.first).to eq(newest_message)
    expect(described_class.last).to eq(oldest_message)
  end

  describe '#contributor' do
    subject { message.contributor }

    let(:contributor) { create(:contributor) }

    describe 'inbound message' do
      let(:message) { create(:message, sender: contributor) }

      it { is_expected.to eql(contributor) }
    end

    context 'outbound' do
      let(:message) do
        create(:message, :outbound, recipient: contributor, broadcasted: true)
      end

      it { is_expected.to eql(contributor) }
    end
  end

  describe '#reply?' do
    subject { message.reply? }

    describe 'inbound message' do
      let(:message) { create(:message, sender: create(:contributor)) }

      it { is_expected.to be(true) }
    end

    # legacy, sender should not be nil in the future, but was before we had User's as senders
    describe 'message has no sender' do
      let(:message) { create(:message, sender: nil, broadcasted: true) }

      it { is_expected.to be(false) }
    end

    describe 'outbound message' do
      let(:message) { create(:message, :outbound) }

      it { is_expected.to be(false) }
    end
  end

  describe '#manually_created?' do
    subject { message.manually_created? }

    context 'message has a creator' do
      let(:message) { create(:message, creator: create(:user)) }

      it { is_expected.to be(true) }
    end

    context 'message has no creator' do
      let(:message) { create(:message, creator: nil) }

      it { is_expected.to be(false) }
    end
  end

  describe 'deeplinks' do
    let(:contributor) { create(:contributor, id: 7) }
    let(:request) { create(:request, id: 6) }
    let(:message) { create(:message, request: request, **params) }

    describe '#conversation_link' do
      subject { message.conversation_link }

      describe 'given a recipient' do
        let(:params) { { sender: nil, recipient: contributor, broadcasted: true } }

        it { is_expected.to eq('/contributors/7/requests/6') }
      end

      describe 'given an inbound message' do
        let(:params) { { recipient: nil, sender: contributor } }

        it { is_expected.to eq('/contributors/7/requests/6') }
      end
    end

    describe '#chat_message_link' do
      subject { message.chat_message_link }

      let(:params) { { id: 8, recipient: nil, sender: contributor } }

      it { is_expected.to eq('/contributors/7/requests/6#message-8') }
    end
  end

  describe 'validations' do
    subject { message }

    let(:message) { build(:message, sender: nil) }

    describe '#raw_data' do
      describe 'missing' do
        before { message.raw_data = nil }

        it { is_expected.to be_valid }

        describe 'but with a given sender' do
          before { message.sender = build(:contributor) }

          it { is_expected.not_to be_valid }
        end
      end
    end
  end

  describe '#after_commit(on: :commit)' do
    let!(:user) { create(:user) }
    let(:request) { create(:request, user: user) }
    let(:message) { create(:message, sender: user, recipient: recipient, broadcasted: true, request: request) }
    let(:recipient) { create(:contributor) }

    describe 'given a recipient with telegram' do
      before do
        recipient.update(telegram_id: 11)
        allow(Telegram.bot).to receive(:send_message).and_return({})
      end

      describe '#blocked' do
        subject do
          perform_enqueued_jobs { message }
          message.reload
          message.blocked
        end

        it { is_expected.to be(false) }

        describe 'but if contributor blocked the telegram bot' do
          before { allow(Telegram.bot).to receive(:send_message).and_raise(Telegram::Bot::Forbidden) }

          it { is_expected.to be(true) }
        end
      end
    end

    describe 'ActivityNotification' do
      subject { create(:message, request: request) }

      it 'Message Received is not created for outbound messages' do
        expect { message }.not_to(change { ActivityNotification.where(type: 'MessageReceived').count })
      end

      it_behaves_like 'an ActivityNotification', 'MessageReceived'
    end
  end

  describe '::counter_culture_fix_counts' do
    subject do
      described_class.counter_culture_fix_counts
      request.reload
    end

    let(:request) { create(:request) }

    describe 'fixes replies counter' do
      before do
        create(:message, :inbound, request: request)
        create(:message, :outbound, request: request)
        create(:message, :inbound) # another requst
        request.update(replies_count: 4711)
      end

      it { expect { subject }.to (change(request, :replies_count)).from(4711).to(1) }
    end
  end
end
