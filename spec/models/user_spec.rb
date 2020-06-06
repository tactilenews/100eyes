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

  describe '#name=' do
    let(:user) { User.new(first_name: 'John', last_name: 'Doe') }
    subject { -> { user.name = 'Till Prochaska' } }
    it { should change { user.first_name }.from('John').to('Till') }
    it { should change { user.last_name }.from('Doe').to('Prochaska') }
  end

  describe '#email' do
    it 'must be unique' do
      create(:user, email: 'user@example.org')
      expect { create(:user, email: 'user@example.org') }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    describe 'no email' do
      subject { -> { build(:user, email: '').save! } }

      it { should_not raise_error }
      it { should change { User.count }.from(0).to(1) }
      it { should change { User.pluck(:email) }.from([]).to([nil]) }

      describe 'given an existing invalid user with empty string as email address' do
        before(:each) do
          create(:user, id: 1)
          User.update(1, email: '')
        end

        it { should_not raise_error }
        it { should change { User.count }.from(1).to(2) }
      end
    end
  end

  describe '#telegram_id' do
    it 'must be unique' do
      User.create!(telegram_id: 1)
      expect { User.create!(telegram_id: 1) }.to raise_error(ActiveRecord::RecordNotUnique)
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

  describe '#reply_via_mail' do
    subject { -> { user.reply_via_mail(email_message) } }
    let(:mail) do
      mail = Mail.new do |m|
        m.from 'user@example.org'
        m.to '100eyes@example.org'
        m.subject 'This is a test email'
      end
      mail.text_part = 'This is a text body part'
      mail
    end
    let(:email_message) { EmailMessage.new(mail) }

    describe 'given no text part' do
      let(:mail) do
        Mail.new do |m|
          m.from 'user@example.org'
          m.to '100eyes@example.org'
          m.subject 'This is a test email'
          m.body 'This is a body'
        end
      end
      it { should_not raise_error }
    end

    it { should_not raise_error }
    it { should_not(change { Message.count }) }
    describe 'given a recent request' do
      before(:each) { create(:message, request: the_request, recipient: user) }

      it { should change { Message.count }.from(1).to(2) }
      it { should_not(change { Photo.count }) }
    end
  end

  describe '#reply_via_telegram' do
    let(:telegram_message) do
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

    subject { -> { user.reply_via_telegram(telegram_message) } }

    it { should_not raise_error }
    it { should_not(change { Message.count }) }

    describe 'given a recent request' do
      before(:each) { create(:message, request: the_request, recipient: user) }

      it { should change { Message.count }.from(1).to(2) }
      it { should_not(change { Photo.count }) }
    end
  end

  describe '#active_request' do
    subject { user.active_request }
    it { should be(nil) }

    describe 'once a request was sent as a message to the user' do
      before(:each) { create(:message, request: the_request, recipient: user) }
      it { should eq(the_request) }
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
end
