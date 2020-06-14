# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request, type: :model do
  let(:user) { create(:user) }

  let(:request) do
    Request.new(
      title: 'Hitchhiker’s Guide',
      text: 'What is the answer to life, the universe, and everything?',
      hints: %w[photo confidential]
    )
  end

  subject { request }

  it 'has title, text, and hints' do
    expect(subject.attributes.keys).to include('title', 'text', 'hints')
  end

  it 'is by default sorted in reverse chronological order' do
    oldest_request = create(:request, created_at: 2.hours.ago)
    newest_request = create(:request, created_at: 1.hour.ago)

    expect(described_class.first).to eq(newest_request)
    expect(described_class.last).to eq(oldest_request)
  end

  describe '#hints' do
    subject { Request.new(title: 'Example').hints }
    it { should match_array([]) }
  end

  describe '#plaintext' do
    subject { request.plaintext }

    it 'returns correct plaintext message' do
      expected = [
        'What is the answer to life, the universe, and everything?',
        I18n.t('request.hints.photo.text'),
        I18n.t('request.hints.confidential.text')
      ].join("\n\n")

      expect(subject).to eql(expected)
    end

    describe 'without hints' do
      let(:request) { create(:request, text: 'Hello World!', hints: []) }
      subject { request.plaintext }

      it { should eql('Hello World!') }
    end
  end

  describe '#messages_by_user' do
    subject { request.messages_by_user }
    let(:request) { create(:request) }

    describe 'with messages by multiple users' do
      let(:request) { create(:request, :with_interlapping_messages_from_two_users) }

      it 'groups by user' do
        expect(subject.keys).to all(be_a User)
        expect(subject.length).to eq(2)
      end

      it 'sorts by most recent message' do
        expect(subject.keys.first.name).to eq('Adam Ackermann')
        expect(subject.keys.second.name).to eq('Zora Zimmermann')
      end
    end

    it 'ignores broadcasted messages' do
      create(:message, request: request, broadcasted: true)
      expect(subject).to be_empty
    end
  end

  describe '#stats' do
    let(:request) { create(:request) }
    let(:stats) { request.stats }

    describe 'given a number of requests, replies and photos' do
      before(:each) do
        create_list(:message, 2)
        create_list(:message, 3, request: request, sender: user)
        create_list(:message, 5, :with_a_photo, request: request)
      end

      describe '[:counts][:replies]' do
        subject { stats[:counts][:replies] }
        it { should eq(8) } # unique users

        describe 'messages from us' do
          before(:each) do
            create(:message, request: request, sender: nil)
          end

          it 'are excluded' do
            should eq(8)
          end
        end
      end

      describe '[:counts][:users]' do
        subject { stats[:counts][:users] }
        it { should eq(6) } # unique users

        describe 'messages from us' do
          before(:each) do
            create(:message, request: request, sender: nil)
          end

          it 'are excluded' do
            should eq(6)
          end
        end
      end

      describe '[:counts][:photos]' do
        subject { stats[:counts][:photos] }
        it { should eq(5) } # unique photos
      end

      describe 'iterating through a list' do
        subject { -> { Request.find_each.map(&:stats) } }
        it { should make_database_queries(count: 4) }

        describe 'eager_load(:messages)' do
          subject { -> { Request.eager_load(:messages).find_each.map(&:stats) } }
          it { should make_database_queries(count: 2) } # better
        end
      end
    end
  end

  describe '::after_create' do
    before(:each) { allow(Request).to receive(:broadcast!).and_call_original } # is stubbed for every other test
    subject { -> { request.save! } }
    describe 'given some existing users in the moment of creation' do
      before(:each) do
        create(:user, id: 1, email: 'somebody@example.org')
        create(:user, id: 2, email: nil, telegram_id: 22, telegram_chat_id: 23)
      end

      it { should change { Message.count }.from(0).to(2) }
      it { should change { Message.pluck(:recipient_id) }.from([]).to([2, 1]) }
      it { should change { Message.pluck(:sender_id) }.from([]).to([nil, nil]) }
      it { should change { Message.pluck(:broadcasted) }.from([]).to([true, true]) }
    end
  end
end
