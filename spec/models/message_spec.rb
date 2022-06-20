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
    let(:contributor) { create(:contributor) }
    subject { message.contributor }

    describe 'with sender' do
      let(:message) { create(:message, sender: contributor) }
      it { should eql(contributor) }
    end

    context 'with recipient' do
      let(:message) { create(:message, :with_recipient, recipient: contributor) }
      it { should eql(contributor) }
    end
  end

  describe '#reply?' do
    subject { message.reply? }
    describe 'message has a sender' do
      let(:message) { create(:message, sender: create(:contributor)) }
      it { should be(true) }
    end

    describe 'message has no sender' do
      let(:message) { create(:message, sender: nil) }
      it { should be(false) }
    end
  end

  describe '#manually_created?' do
    subject { message.manually_created? }
    context 'message has a creator' do
      let(:message) { create(:message, creator: create(:user)) }
      it { should be(true) }
    end

    context 'message has no creator' do
      let(:message) { create(:message, creator: nil) }
      it { should be(false) }
    end
  end

  describe 'deeplinks' do
    let(:contributor) { create(:contributor, id: 7) }
    let(:request) { create(:request, id: 6) }
    let(:message) { create(:message, request: request, **params) }

    describe '#conversation_link' do
      subject { message.conversation_link }

      describe 'given a recipient' do
        let(:params) { { sender: nil, recipient: contributor } }
        it { should eq('/contributors/7/requests/6') }
      end

      describe 'given a sender' do
        let(:params) { { recipient: nil, sender: contributor } }
        it { should eq('/contributors/7/requests/6') }
      end
    end

    describe '#chat_message_link' do
      subject { message.chat_message_link }
      let(:params) { { id: 8, recipient: nil, sender: contributor } }
      it { should eq('/contributors/7/requests/6#chat-row-8') }
    end
  end

  describe 'validations' do
    let(:message) { build(:message, sender: nil) }
    subject { message }
    describe '#raw_data' do
      describe 'missing' do
        before(:each) { message.raw_data = nil }
        it { should be_valid }
        describe 'but with a given sender' do
          before(:each) { message.sender = build(:contributor) }
          it { should_not be_valid }
        end
      end
    end
  end

  describe '#after_commit(on: :commit)' do
    let(:message) { create(:message, sender: nil, recipient: recipient) }
    let(:recipient) { create(:contributor) }

    describe 'given a recipient with telegram' do
      before do
        recipient.update(telegram_id: 11)
      end

      describe '#blocked' do
        subject do
          perform_enqueued_jobs { message }
          message.reload
          message.blocked
        end

        it { should be(false) }
        describe 'but if contributor blocked the telegram bot' do
          before(:each) { allow(Telegram.bot).to receive(:send_message).and_raise(Telegram::Bot::Forbidden) }
          it { should be(true) }
        end
      end
    end

    describe 'ActivityNotification' do
      subject { create(:message, sender: create(:contributor), request: create(:request)) }

      it 'is not created for replies' do
        expect { message }.not_to(change { ActivityNotification.where(type: 'MessageReceived').count })
      end

      it_behaves_like 'activity_notifications', 'MessageReceived'
    end
  end
end
