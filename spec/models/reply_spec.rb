# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reply, type: :model do

  let(:request) do
    Request.new(
      title: 'Hitchhiker’s Guide',
      text: 'What is the answer to life, the universe, and everything?',
      hints: %w[photo confidential]
    )
  end

  it 'is by default sorted in reverse chronological order' do
    oldest_reply = create(:reply, created_at: 2.hours.ago)
    newest_reply = create(:reply, created_at: 1.hour.ago)

    expect(described_class.first).to eq(newest_reply)
    expect(described_class.last).to eq(oldest_reply)
  end

  describe '::from_telegram_message' do
    subject do
      lambda {
        Reply.from_telegram_message(
          'text' => 'The answer is 42.',
          'from' => {
            'id' => 4711,
            'is_bot' => false,
            'first_name' => 'Robert',
            'last_name' => 'Schäfer',
            'language_code' => 'en'
          },
          'chat' => { 'id' => 146_338_764 }
        )
      }
    end
    it { should_not raise_error }
    it { should_not(change { Reply.count }) }

    describe 'given a recent request' do
      before(:each) { request.save! }
      it { should change { Reply.count }.from(0).to(1) }
      it { should_not(change { Photo.count }) }
    end
  end
end
