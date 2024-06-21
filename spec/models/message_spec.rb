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

    describe 'inbound message' do
      let(:message) { create(:message, sender: contributor) }
      it { should eql(contributor) }
    end

    context 'outbound' do
      let(:message) do
        create(:message, :outbound, recipient: contributor, broadcasted: true)
      end
      it { should eql(contributor) }
    end
  end

  describe '#reply?' do
    subject { message.reply? }
    describe 'inbound message' do
      let(:message) { create(:message, sender: create(:contributor)) }
      it { should be(true) }
    end

    # legacy, sender should not be nil in the future, but was before we had User's as senders
    describe 'message has no sender' do
      let(:message) { create(:message, sender: nil, broadcasted: true) }
      it { should be(false) }
    end

    describe 'outbound message' do
      let(:message) { create(:message, :outbound) }
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

    describe '#chat_message_link' do
      subject { message.chat_message_link }
      let(:params) { { id: 8, recipient: nil, sender: contributor } }
      it 'should link to message within the contributors conversations' do
        should eq('/contributors/7/conversations#message-8')
      end
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
    let!(:user) { create(:user) }
    let(:request) { create(:request, user: user, organization: organization) }
    let(:message) { create(:message, sender: user, recipient: recipient, broadcasted: true, request: request) }
    let(:organization) do
      create(:organization, name: '100eyes', telegram_bot_api_key: 'TELEGRAM_BOT_API_KEY', telegram_bot_username: 'USERNAME')
    end
    let(:recipient) { create(:contributor, organization: organization) }

    describe 'given a recipient with telegram' do
      before do
        Telegram.reset_bots
        Telegram.bots_config = {
          organization.id => { token: organization.telegram_bot_api_key, username: organization.telegram_bot_username }
        }
        recipient.update(telegram_id: 11)
        allow(organization.telegram_bot).to receive(:send_message).and_return({})
      end

      describe '#blocked' do
        subject do
          perform_enqueued_jobs { message }
          message.reload
          message.blocked
        end

        it { should be(false) }
        describe 'but if contributor blocked the telegram bot' do
          before { allow(organization.telegram_bot).to receive(:send_message).and_raise(Telegram::Bot::Forbidden) }
          it { should be(true) }
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
    let(:request) { create(:request) }

    subject do
      described_class.counter_culture_fix_counts
      request.reload
    end

    describe 'fixes replies counter' do
      before do
        create(:message, :inbound, request: request)
        create(:message, :outbound, request: request)
        create(:message, :inbound) # another requst
        request.update(replies_count: 4711)
      end

      it { expect { subject }.to (change { request.replies_count }).from(4711).to(1) }
    end
  end
end
