# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  it 'is by default sorted in reverse chronological order' do
    oldest_message = create(:message, created_at: 2.hours.ago)
    newest_message = create(:message, created_at: 1.hour.ago)

    expect(described_class.first).to eq(newest_message)
    expect(described_class.last).to eq(oldest_message)
  end

  describe '#reply?' do
    subject { message.reply? }
    describe 'message has a sender' do
      let(:message) { create(:message, sender: create(:user)) }
      it { should be(true) }
    end

    describe 'message has no sender' do
      let(:message) { create(:message, sender: nil) }
      it { should be(false) }
    end
  end

  describe 'deeplinks' do
    let(:user) { create(:user, id: 7) }
    let(:request) { create(:request, id: 6) }
    let(:message) { create(:message, request: request, **params) }

    describe '#conversation_link' do
      subject { message.conversation_link }

      describe 'given a recipient' do
        let(:params) { { sender: nil, recipient: user } }
        it { should eq('/users/7/requests/6') }
      end

      describe 'given a sender' do
        let(:params) { { recipient: nil, sender: user } }
        it { should eq('/users/7/requests/6') }
      end
    end

    describe '#chat_message_link' do
      subject { message.chat_message_link }
      let(:params) { { id: 8, recipient: nil, sender: user } }
      it { should eq('/users/7/requests/6#chat-row-8') }
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
          before(:each) { message.sender = build(:user) }
          it { should_not be_valid }
        end
      end
    end
  end
end
