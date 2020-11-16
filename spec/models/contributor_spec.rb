# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contributor, type: :model do
  let(:the_request) do
    create(:request,
           title: 'Hitchhiker’s Guide',
           text: 'What is the answer to life, the universe, and everything?',
           hints: %w[photo confidential])
  end
  let(:contributor) { create(:contributor) }

  it 'is sorted in alphabetical order' do
    zora = create(:contributor, first_name: 'Zora', last_name: 'Zimmermann')
    adam_zimmermann = create(:contributor, first_name: 'Adam', last_name: 'Zimmermann')
    adam_ackermann = create(:contributor, first_name: 'Adam', last_name: 'Ackermann')

    expect(Contributor.first).to eq(adam_ackermann)
    expect(Contributor.second).to eq(adam_zimmermann)
    expect(Contributor.third).to eq(zora)
  end

  describe '.find_by_email' do
    subject { described_class.with_lowercased_email(address) }

    describe 'with lowercase address' do
      let(:contributor) { create(:contributor, email: 'UPPER@EXAMPLE.ORG') }
      let(:address) { 'upper@example.org' }

      it { should eq(contributor) }
    end

    describe 'with uppercase address' do
      let(:contributor) { create(:contributor, email: 'lower@example.org') }
      let(:address) { 'LOWER@EXAMPLE.ORG' }

      it { should eq(contributor) }
    end

    describe 'with multiple addresses' do
      let(:contributor) { create(:contributor, email: 'zora@example.org') }
      let(:address) { ['other@example.org', 'zora@example.org'] }

      it { should eq(contributor) }
    end
  end

  describe '#email' do
    it 'must be unique' do
      create(:contributor, email: 'contributor@example.org')
      expect { create(:contributor, email: 'contributor@example.org') }.to raise_error(ActiveRecord::RecordInvalid)
      expect { create(:contributor, email: 'CONTRIBUTOR@example.org') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    describe 'two contributor accounts without email' do
      before(:each) { create(:contributor, email: nil) }
      subject { build(:contributor, email: nil) }
      it { should be_valid }
    end

    describe 'no email' do
      subject { -> { build(:contributor, email: '').save! } }

      it { should_not raise_error }
      it { should change { Contributor.count }.from(0).to(1) }
      it { should change { Contributor.pluck(:email) }.from([]).to([nil]) }

      describe 'given an existing invalid contributor with empty string as email address' do
        before(:each) do
          build(:contributor, id: 1).save!(validate: false)
        end

        it { should_not raise_error }
        it { should change { Contributor.count }.from(1).to(2) }
      end
    end
  end

  describe '#telegram_id' do
    it 'must be unique' do
      create(:contributor, telegram_id: 1)
      expect { build(:contributor, telegram_id: 1).save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '#replied_to_requests' do
    it 'omits duplicates' do
      create(:message, request: the_request, sender: contributor)
      create(:message, request: the_request, sender: contributor)

      expect(contributor.replied_to_requests).to contain_exactly(the_request)
    end
  end

  describe '#channels' do
    subject { contributor.channels }

    describe 'given a contributor without telegram or email' do
      let(:contributor) { create(:contributor, telegram_id: nil, telegram_chat_id: nil, email: nil) }
      it { should be_empty }
    end

    describe 'given a contributor with email' do
      let(:contributor) { create(:contributor, email: 'contributor@example.org') }
      it { should contain_exactly(:email) }
    end

    describe 'given a contributor with telegram and email' do
      let(:contributor) { create(:contributor, telegram_id: '123', telegram_chat_id: '456', email: 'contributor@example.org') }
      it { should contain_exactly(:telegram, :email) }
    end
  end

  describe '#telegram?' do
    subject { contributor.telegram? }

    describe 'given a contributor with a telegram_id and telegram_chat_id' do
      let(:contributor) { create(:contributor, telegram_id: '123', telegram_chat_id: '456') }
      it { should be(true) }
    end

    describe 'given a contributor without telegram_id and telegram_chat_id' do
      let(:contributor) { create(:contributor, telegram_id: nil, telegram_chat_id: nil) }
      it { should be(false) }
    end
  end

  describe '#email?' do
    subject { contributor.email? }

    describe 'given a contributor with an email address' do
      let(:contributor) { create(:contributor, email: 'contributor@example.org') }
      it { should be(true) }
    end

    describe 'given a contributor without an email address' do
      let(:contributor) { create(:contributor, email: nil) }
      it { should be(false) }
    end
  end

  describe '#conversation_about' do
    subject { contributor.conversation_about(the_request) }

    describe 'given some requests and messages' do
      let(:messages) do
        [
          create(:message, text: 'This is included', sender: contributor, request: the_request),
          create(:message, text: 'This is not included', sender: contributor, request: create(:request, text: 'Another request')),
          create(:message, text: 'This is included, too', sender: contributor, request: the_request),
          create(:message, text: 'This is not a message of the contributor', request: the_request),
          create(:message, text: 'Message with the contributor as recipient', recipient: contributor, request: the_request)
        ]
      end

      before(:each) do
        messages # make sure all records are written to the database
      end

      it { should include(messages[0]) }
      it { should_not include(messages[1]) }
      it 'should be orderd by `created_at`' do
        should eq([messages[0], messages[2], messages[4]])
      end
      it 'does not include messages of other contributors' do
        should_not include(messages[3])
      end
      it { should include(messages[4]) }
    end
  end

  describe '#reply' do
    subject { -> { contributor.reply(message_decorator) } }
    describe 'given an EmailMessage' do
      let(:mail) do
        mail = Mail.new do |m|
          m.from 'contributor@example.org'
          m.to '100eyes@example.org'
          m.subject 'This is a test email'
        end
        mail.text_part = 'This is a text body part'
        mail
      end
      let(:message_decorator) { EmailMessage.new(mail) }

      it { should_not raise_error }
      it { should_not(change { Message.count }) }
      describe 'given a recent request' do
        before(:each) { create(:message, request: the_request, recipient: contributor) }

        it { should change { Message.count }.from(1).to(2) }
        it { should_not(change { Photo.count }) }
      end
    end

    describe 'given a TelegramMessage' do
      let(:message_decorator) do
        TelegramMessage.new(
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
      end

      it { should_not raise_error }
      it { should_not(change { Message.count }) }

      describe 'given a recent request' do
        before(:each) { create(:message, request: the_request, recipient: contributor) }

        it { should change { Message.count }.from(1).to(2) }
        it { should_not(change { Photo.count }) }
      end
    end
  end

  describe '#active_request' do
    subject { contributor.active_request }
    it { should be(nil) }

    describe 'once a request was sent as a message to the contributor' do
      before(:each) { create(:message, request: the_request, recipient: contributor) }
      it { should eq(the_request) }
    end

    describe 'if a request was created' do
      before(:each) { the_request }
      describe 'and afterwards a contributor joins' do
        before(:each) { contributor }
        it { should eq(the_request) }
      end
    end

    describe 'when many requests are sent to the contributor' do
      before(:each) do
        another_request = create(:request, created_at: 1.day.ago)
        create(:message, request: the_request, recipient: contributor)
        create(:message, request: another_request, recipient: contributor)
      end

      it { should eq(the_request) }
    end
  end

  describe '#recent_replies' do
    subject { contributor.recent_replies }
    let(:old_date) { ActiveSupport::TimeZone['Berlin'].parse('2011-04-12 2pm') }
    let(:old_message) { create(:message, created_at: old_date, sender: contributor, request: the_request) }
    let(:another_request) { create(:request) }
    let(:old_request) { create(:request, created_at: (old_date - 1.day)) }

    before(:each) do
      create_list(:message, 3, sender: contributor, request: the_request)
      create(:message, sender: contributor, request: old_request)
      create(:message, sender: contributor, request: another_request)
      old_message
    end

    it { expect(subject.length).to eq(3) }

    it 'chooses one reply per request' do
      expect(subject.map(&:request)).to match_array([the_request, another_request, old_request])
    end

    it 'orders replies chronologically in descending order' do
      expect(subject).to eq(subject.sort_by(&:created_at).reverse)
    end

    describe 'number of database calls' do
      subject { -> { contributor.recent_replies.first.request } }
      it { should make_database_queries(count: 1) }
    end
  end

  describe '.with_tags' do
    let!(:contributors) { create_list(:contributor, 3).to_a }
    let!(:teachers) { create_list(:contributor, 2, tag_list: 'teacher').to_a }
    let!(:teaching_pig_farmer) { create(:contributor, tag_list: 'teacher,pig farmer') }

    context 'returns count of' do
      it 'all contributors if no tag_list present' do
        expect(Contributor.with_tags).to contain_exactly(*contributors, *teachers, teaching_pig_farmer)
      end

      it 'contributors with a specific tag' do
        expect(Contributor.with_tags(['teacher'])).to contain_exactly(*teachers, teaching_pig_farmer)
      end

      it 'aggregate contributors with a specific tag' do
        expect(Contributor.with_tags(['teacher', 'pig farmer'])).to contain_exactly(teaching_pig_farmer)
      end
    end
  end

  describe '.email_taken?' do
    let!(:contributor) { create(:contributor, email: 'zora@example.org') }

    subject { Contributor.email_taken?(address) }

    describe 'given the exact address' do
      let(:address) { 'zora@example.org' }
      it { should be(true) }
    end

    describe 'given a semantically equivalent address' do
      let(:address) { 'ZORA@EXAMPLE.ORG' }
      it { should be(true) }
    end

    describe 'given a different address' do
      let(:address) { 'adam@example.org' }
      it { should be(false) }
    end
  end

  describe 'scope ::active' do
    subject { Contributor.active }
    context 'given some inactive and active contributors' do
      let(:active_contributor) { create(:contributor, active: true) }
      let(:inactive_contributor) { create(:contributor, active: false) }

      before { active_contributor && inactive_contributor }

      it 'returns only active contributors' do
        should eq([active_contributor])
      end
    end
  end

  describe '.active' do
    subject { contributor.active }
    it { should be(true) }

    describe 'given "deactivated_at" timestamp' do
      let(:contributor) { create(:contributor, deactivated_at: 1.day.ago) }
      it { should be(false) }
    end
  end

  describe '.active=' do
    describe 'given active contributor' do
      let(:contributor) { create(:contributor, deactivated_at: nil) }
      describe 'false' do
        it { expect { contributor.active = false }.to change { contributor.deactivated_at.is_a?(ActiveSupport::TimeWithZone) }.to(true) }
        it { expect { contributor.active = false }.to change { contributor.active? }.to(false) }
        it { expect { contributor.active = '0' }.to change { contributor.active? }.to(false) }
        it { expect { contributor.active = 'off' }.to change { contributor.active? }.to(false) }
      end
    end

    describe 'given deactivated contributor' do
      let(:contributor) { create(:contributor, deactivated_at: 1.day.ago) }
      describe 'true' do
        it { expect { contributor.active = true }.to change { contributor.deactivated_at.is_a?(ActiveSupport::TimeWithZone) }.to(false) }
        it { expect { contributor.active = true }.to change { contributor.active? }.to(true) }
        it { expect { contributor.active = '1' }.to change { contributor.active? }.to(true) }
        it { expect { contributor.active = 'on' }.to change { contributor.active? }.to(true) }
      end
    end
  end
end
