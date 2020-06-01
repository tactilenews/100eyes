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

  describe '.hints' do
    subject { Request.new(title: 'Example').hints }
    it { should match_array([]) }
  end

  describe '.plaintext' do
    subject { request.plaintext }

    it 'returns correct plaintext message' do
      expected  = "Hallo, die Redaktion hat eine neue Frage an Sie:\n\n"
      expected += "What is the answer to life, the universe, and everything?\n\n"
      expected += "#{I18n.t 'request.hints.photo.text'}\n\n"
      expected += "#{I18n.t 'request.hints.confidential.text'}\n\n"
      expected += 'Vielen Dank für Ihre Hilfe bei unserer Recherche!'

      expect(subject).to eql(expected)
    end

    describe 'without hints' do
      subject { Request.new(title: 'Example', text: 'Hello World!', hints: []).plaintext }

      it 'returns correct plaintext message' do
        expected  = "Hallo, die Redaktion hat eine neue Frage an Sie:\n\n"
        expected += "Hello World!\n\n"
        expected += 'Vielen Dank für Ihre Hilfe bei unserer Recherche!'

        expect(subject).to eql(expected)
      end
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
    end
  end
end
