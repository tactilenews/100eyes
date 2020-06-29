# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:the_request) do
    create(:request,
           title: 'Hitchhiker’s Guide',
           text: 'What is the answer to life, the universe, and everything?',
           hints: %w[photo confidential])
  end
  let(:user) { create(:user) }

  it 'is sorted in alphabetical order' do
    zora = create(:user, first_name: 'Zora', last_name: 'Zimmermann')
    adam_zimmermann = create(:user, first_name: 'Adam', last_name: 'Zimmermann')
    adam_ackermann = create(:user, first_name: 'Adam', last_name: 'Ackermann')

    expect(User.first).to eq(adam_ackermann)
    expect(User.second).to eq(adam_zimmermann)
    expect(User.third).to eq(zora)
  end

  describe '.find_by_email' do
    subject { described_class.find_by_email(address) }

    describe 'with lowercase address' do
      let(:user) { create(:user, email: 'UPPER@EXAMPLE.ORG') }
      let(:address) { 'upper@example.org' }

      it { should eq(user) }
    end

    describe 'with uppercase address' do
      let(:user) { create(:user, email: 'lower@example.org') }
      let(:address) { 'LOWER@EXAMPLE.ORG' }

      it { should eq(user) }
    end

    describe 'with multiple addresses' do
      let(:user) { create(:user, email: 'zora@example.org') }
      let(:address) { ['other@example.org', 'zora@example.org'] }

      it { should eq(user) }
    end
  end

  describe '#email' do
    it 'must be unique' do
      create(:user, email: 'user@example.org')
      expect { create(:user, email: 'user@example.org') }.to raise_error(ActiveRecord::RecordInvalid)
      expect { create(:user, email: 'USER@example.org') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    describe 'two user accounts without email' do
      before(:each) { create(:user, email: nil) }
      subject { build(:user, email: nil) }
      it { should be_valid }
    end

    describe 'no email' do
      subject { -> { build(:user, email: '').save! } }

      it { should_not raise_error }
      it { should change { User.count }.from(0).to(1) }
      it { should change { User.pluck(:email) }.from([]).to([nil]) }

      describe 'given an existing invalid user with empty string as email address' do
        before(:each) do
          build(:user, id: 1).save!(validate: false)
        end

        it { should_not raise_error }
        it { should change { User.count }.from(1).to(2) }
      end
    end
  end

  describe '#telegram_id' do
    it 'must be unique' do
      create(:user, telegram_id: 1)
      expect { build(:user, telegram_id: 1).save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '#replied_to_requests' do
    it 'omits duplicates' do
      create(:message, request: the_request, sender: user)
      create(:message, request: the_request, sender: user)

      expect(user.replied_to_requests).to contain_exactly(the_request)
    end
  end

  describe '#channels' do
    subject { user.channels }

    describe 'given a user without telegram or email' do
      let(:user) { create(:user, telegram_id: nil, telegram_chat_id: nil, email: nil) }
      it { should be_empty }
    end

    describe 'given a user with email' do
      let(:user) { create(:user, email: 'user@example.org') }
      it { should contain_exactly(:email) }
    end

    describe 'given a user with telegram and email' do
      let(:user) { create(:user, telegram_id: '123', telegram_chat_id: '456', email: 'user@example.org') }
      it { should contain_exactly(:telegram, :email) }
    end
  end

  describe '#telegram?' do
    subject { user.telegram? }

    describe 'given a user with a telegram_id and telegram_chat_id' do
      let(:user) { create(:user, telegram_id: '123', telegram_chat_id: '456') }
      it { should be(true) }
    end

    describe 'given a user without telegram_id and telegram_chat_id' do
      let(:user) { create(:user, telegram_id: nil, telegram_chat_id: nil) }
      it { should be(false) }
    end
  end

  describe '#email?' do
    subject { user.email? }

    describe 'given a user with an email address' do
      let(:user) { create(:user, email: 'user@example.org') }
      it { should be(true) }
    end

    describe 'given a user without an email address' do
      let(:user) { create(:user, email: nil) }
      it { should be(false) }
    end
  end

  describe '#conversation_about' do
    subject { user.conversation_about(the_request) }

    describe 'given some requests and messages' do
      let(:messages) do
        [
          create(:message, text: 'This is included', sender: user, request: the_request),
          create(:message, text: 'This is not included', sender: user, request: create(:request, text: 'Another request')),
          create(:message, text: 'This is included, too', sender: user, request: the_request),
          create(:message, text: 'This is not a message of the user', request: the_request),
          create(:message, text: 'This is a message with the user as recipient', recipient: user, request: the_request)
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
      it 'does not include messages of other users' do
        should_not include(messages[3])
      end
      it { should include(messages[4]) }
    end
  end

  describe '#reply' do
    subject { -> { user.reply(message_decorator) } }
    describe 'given an EmailMessage' do
      let(:mail) do
        mail = Mail.new do |m|
          m.from 'user@example.org'
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
        before(:each) { create(:message, request: the_request, recipient: user) }

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
        before(:each) { create(:message, request: the_request, recipient: user) }

        it { should change { Message.count }.from(1).to(2) }
        it { should_not(change { Photo.count }) }
      end
    end
  end

  describe '#active_request' do
    subject { user.active_request }
    it { should be(nil) }

    describe 'once a request was sent as a message to the user' do
      before(:each) { create(:message, request: the_request, recipient: user) }
      it { should eq(the_request) }
    end

    describe 'if a request was created' do
      before(:each) { the_request }
      describe 'and afterwards a user joins' do
        before(:each) { user }
        it { should eq(the_request) }
      end
    end

    describe 'when many requests are sent to the user' do
      before(:each) do
        another_request = create(:request, created_at: 1.day.ago)
        create(:message, request: the_request, recipient: user)
        create(:message, request: another_request, recipient: user)
      end

      it { should eq(the_request) }
    end
  end

  describe '#recent_replies' do
    subject { user.recent_replies }
    let(:old_date) { ActiveSupport::TimeZone['Berlin'].parse('2011-04-12 2pm') }
    let(:old_message) { create(:message, created_at: old_date, sender: user, request: the_request) }
    let(:another_request) { create(:request) }
    let(:old_request) { create(:request, created_at: (old_date - 1.day)) }

    before(:each) do
      create_list(:message, 3, sender: user, request: the_request)
      create(:message, sender: user, request: old_request)
      create(:message, sender: user, request: another_request)
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
      subject { -> { user.recent_replies.first.request } }
      it { should make_database_queries(count: 1) }
    end
  end
end
