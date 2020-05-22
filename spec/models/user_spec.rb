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
      User.create!(email: 'user@example.org')
      expect { User.create!(email: 'user@example.org') }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '#telegram_id' do
    it 'must be unique' do
      User.create!(telegram_id: 1)
      expect { User.create!(telegram_id: 1) }.to raise_error(ActiveRecord::RecordNotUnique)
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

  describe '#replies_for_request' do
    subject { user.replies_for_request(the_request) }
    let(:the_request) { Request.create! text: 'One request' }
    let(:user) { User.create! first_name: 'Max', last_name: 'Mustermann' }

    describe 'given two replies for two different requests' do
      before(:each) do
        @reply_a = Reply.create! text: 'This is included', user: user, request: the_request
        @reply_b = Reply.create! text: 'This is not included', user: user, request: (Request.create! text: 'Another request')
      end
      it { should include(@reply_a) }
      it { should_not include(@reply_b) }
    end
  end

  describe '#reply_via_mail' do
    let(:user) { create(:user) }
    let(:mail) { instance_double('Mail::Message', decoded: 'A nice email') }

    subject { -> { user.reply_via_mail(mail) } }
    it { should_not raise_error }
    it { should_not(change { Reply.count }) }
    describe 'given a recent request' do
      before(:each) { request.save! }
      let(:request) do
        Request.new(
          title: 'Hitchhiker’s Guide',
          text: 'What is the answer to life, the universe, and everything?',
          hints: %w[photo confidential]
        )
      end

      it { should change { Reply.count }.from(0).to(1) }
      it { should_not(change { Photo.count }) }
    end
  end

  describe '#reply_via_telegram' do
    let(:user) { create(:user) }

    subject do
      lambda {
        user.reply_via_telegram(
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
      let(:request) do
        Request.new(
          title: 'Hitchhiker’s Guide',
          text: 'What is the answer to life, the universe, and everything?',
          hints: %w[photo confidential]
        )
      end

      it { should change { Reply.count }.from(0).to(1) }
      it { should_not(change { Photo.count }) }
    end
  end
end
