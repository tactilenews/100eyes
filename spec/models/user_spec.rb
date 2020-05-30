# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
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

  describe '#requests' do
    let(:user) { create(:user) }
    let(:request) { create(:request) }

    it 'omits duplicates' do
      create(:message, request: request, user: user)
      create(:message, request: request, user: user)

      expect(user.requests).to contain_exactly(request)
    end
  end

  describe '#channels' do
    subject { user.channels }

    describe 'given a user without telegram or email' do
      let(:user) { User.create! }
      it { should be_empty }
    end

    describe 'given a user with email' do
      let(:user) { User.create!(email: 'user@example.org') }
      it { should contain_exactly(:email) }
    end

    describe 'given a user with telegram and email' do
      let(:user) { User.create!(telegram_id: '123', telegram_chat_id: '456', email: 'user@example.org') }
      it { should contain_exactly(:telegram, :email) }
    end
  end

  describe '#telegram?' do
    subject { user.telegram? }

    describe 'given a user with a telegram_id and telegram_chat_id' do
      let(:user) { User.create!(telegram_id: '123', telegram_chat_id: '456') }
      it { should be(true) }
    end

    describe 'given a user without telegram_id and telegram_chat_id' do
      let(:user) { User.create! }
      it { should be(false) }
    end
  end

  describe '#email?' do
    subject { user.email? }

    describe 'given a user with an email address' do
      let(:user) { User.create!(email: 'user@example.org') }
      it { should be(true) }
    end

    describe 'given a user without an email address' do
      let(:user) { User.create! }
      it { should be(false) }
    end
  end

  describe '#messages_for_request' do
    subject { user.messages_for_request(the_request) }
    let(:the_request) { Request.create! text: 'One request' }
    let(:user) { User.create! first_name: 'Max', last_name: 'Mustermann' }

    describe 'given two messages for two different requests' do
      let(:messages) do
        [
          create(:message, text: 'This is included', user: user, request: the_request),
          create(:message, text: 'This is not included', user: user, request: (Request.create! text: 'Another request')),
          create(:message, text: 'This is included, too', user: user, request: the_request),
          create(:message, text: 'This is not a message of the user', request: the_request)
        ]
      end

      before(:each) do
        messages # make sure all records are written to the database
      end

      it { should include(messages[0]) }
      it { should_not include(messages[1]) }
      it 'should be orderd by `created_at`' do
        should eq([messages[0], messages[2]])
      end
      it 'does not include messages of other users' do
        should_not include(messages[3])
      end
    end
  end

  describe '#reply_via_mail' do
    let(:user) { create(:user) }
    let(:mail) { instance_double('Mail::Message', decoded: 'A nice email') }

    subject { -> { user.reply_via_mail(mail) } }
    it { should_not raise_error }
    it { should_not(change { Message.count }) }
    describe 'given a recent request' do
      before(:each) { request.save! }
      let(:request) do
        Request.new(
          title: 'Hitchhiker’s Guide',
          text: 'What is the answer to life, the universe, and everything?',
          hints: %w[photo confidential]
        )
      end

      it { should change { Message.count }.from(0).to(1) }
      it { should_not(change { Photo.count }) }
    end
  end

  describe '#reply_via_telegram' do
    let(:user) { create(:user) }
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
      before(:each) { request.save! }
      let(:request) do
        Request.new(
          title: 'Hitchhiker’s Guide',
          text: 'What is the answer to life, the universe, and everything?',
          hints: %w[photo confidential]
        )
      end

      it { should change { Message.count }.from(0).to(1) }
      it { should_not(change { Photo.count }) }
    end
  end
end
