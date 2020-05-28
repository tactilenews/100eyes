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

  describe '::active_request' do
    it 'overrides any order() scope' do
      create(:request, id: 1)
      request2 = create(:request, id: 2)
      expect(Request.reorder(created_at: :asc).active_request).to eq(request2)
    end
  end

  describe '#stats' do
    let(:request) { create(:request) }
    let(:stats) { request.stats }

    describe 'given a number of requests, replies and photos' do
      before(:each) do
        create_list(:reply, 2)
        create_list(:reply, 3, request: request, user: user)
        create_list(:reply, 5, :with_a_photo, request: request)
      end

      describe '[:counts][:replies]' do
        subject { stats[:counts][:replies] }
        it { should eq(8) } # unique users
      end

      describe '[:counts][:users]' do
        subject { stats[:counts][:users] }
        it { should eq(6) } # unique users
      end

      describe '[:counts][:photos]' do
        subject { stats[:counts][:photos] }
        it { should eq(5) } # unique photos
      end

      describe 'iterating through a list' do
        subject { -> { Request.find_each.map(&:stats) } }
        it { should make_database_queries(count: 4) }

        describe 'eager_load(:replies)' do
          subject { -> { Request.eager_load(:replies).find_each.map(&:stats) } }
          it { should make_database_queries(count: 2) } # better
        end
      end
    end
  end
end
