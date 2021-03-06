# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request, type: :model do
  let(:contributor) { create(:contributor) }

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

  describe 'request tag_list persists' do
    let!(:contributor) { create(:contributor, tag_list: ['programmer']) }
    let!(:request) { create(:request, tag_list: ['programmer']) }

    before(:each) do
      contributor.tag_list = ''
      contributor.save
      contributor.reload
    end

    it 'even with no contributors with tag' do
      expect(contributor.tag_list).to eq([])
      expect(Contributor.all_tags.map(&:name)).to eq([])
      request.reload
      expect(request.tag_list).to eq(['programmer'])
      expect(Request.all_tags.map(&:name)).to eq(['programmer'])
    end
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

  describe '#messages_by_contributor' do
    subject { request.messages_by_contributor }
    let(:request) { create(:request) }

    describe 'with messages by multiple contributors' do
      let(:request) { create(:request, :with_interlapping_messages_from_two_contributors) }

      it 'groups by contributor' do
        expect(subject.keys).to all(be_a Contributor)
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
        delivered_messages = create_list(:message, 7, :with_recipient, request: request)
        # _ is some unresponsive recipient
        responsive_recipient, _, *other_recipients = delivered_messages.map(&:recipient)
        create_list(:message, 3, request: request, sender: responsive_recipient)
        other_recipients.each do |recipient|
          create(:message, :with_a_photo, sender: recipient, request: request)
        end
      end

      describe '[:counts][:replies]' do
        subject { stats[:counts][:replies] }
        it { should eq(8) } # unique contributors

        describe 'messages from us' do
          before(:each) do
            create(:message, request: request, sender: nil)
          end

          it 'are excluded' do
            should eq(8)
          end
        end
      end

      describe '[:counts][:contributors]' do
        subject { stats[:counts][:contributors] }
        it { should eq(6) } # unique contributors

        describe 'messages from us' do
          before(:each) do
            create(:message, request: request, sender: nil)
          end

          it 'are excluded' do
            should eq(6)
          end
        end
      end

      describe '[:counts][:recipients]' do
        subject { stats[:counts][:recipients] }
        it { should eq(7) }
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
    describe 'given some existing contributors in the moment of creation' do
      before(:each) do
        create(:contributor, id: 1, email: 'somebody@example.org')
        create(:contributor, id: 2, email: nil, telegram_id: 22)
      end

      it { should change { Message.count }.from(0).to(2) }
      it { should change { Message.pluck(:recipient_id) }.from([]).to([2, 1]) }
      it { should change { Message.pluck(:sender_id) }.from([]).to([nil, nil]) }
      it { should change { Message.pluck(:broadcasted) }.from([]).to([true, true]) }
    end

    describe 'creates message only for contributors tagged with tag_list' do
      let(:request) do
        Request.new(
          title: 'Hitchhiker’s Guide',
          text: 'What is the answer to life, the universe, and everything?',
          hints: %w[photo confidential],
          tag_list: 'programmer'
        )
      end
      before(:each) do
        create(:contributor, id: 1, email: 'somebody@example.org', tag_list: ['programmer'])
        create(:contributor, id: 2, email: nil, telegram_id: 22)
      end

      it { should change { Message.count }.from(0).to(1) }
      it { should change { Message.pluck(:recipient_id) }.from([]).to([1]) }
      it { should change { Message.pluck(:sender_id) }.from([]).to([nil]) }
      it { should change { Message.pluck(:broadcasted) }.from([]).to([true]) }
    end

    describe 'given contributors who are deactivated' do
      before(:each) do
        create(:contributor, id: 3, email: 'deactivated@example.org', active: false)
        create(:contributor, id: 4, email: 'activated@example.org', active: true)
        create(:contributor, id: 5, telegram_id: 24, active: false)
      end

      it { should change { Message.count }.from(0).to(1) }
      it { should change { Message.pluck(:recipient_id) }.from([]).to([4]) }
      it { should change { Message.pluck(:sender_id) }.from([]).to([nil]) }
      it { should change { Message.pluck(:broadcasted) }.from([]).to([true]) }
    end
  end
end
