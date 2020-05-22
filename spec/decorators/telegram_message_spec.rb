# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramMessage do
  let(:telegram_message) { TelegramMessage.new message }
  describe '#text' do
    subject { telegram_message.text }

    describe 'given a message with a `text` attribute' do
      let(:message) { { text: 'Ich bin eine normale Nachricht' } }
      it { should eq('Ich bin eine normale Nachricht') }
    end

    describe 'given a photo with a `caption`' do
      let(:message) do
        {  photo: [
          { file_id: 'AAA', file_size: 6293, width: 320, height: 120 },
          { file_id: 'AAB', file_size: 23_388, width: 800, height: 299 },
          { file_id: 'AAC', file_size: 41_585, width: 1280, height: 478 }
        ], caption: 'Das hier ist die Überschrift eine Fotos' }
      end
      it { should eq('Das hier ist die Überschrift eine Fotos') }
    end
  end

  describe '#photos' do
    subject { telegram_message.photos }
    describe 'given a message without photos' do
      let(:message) { { text: 'Ich bin eine normale Nachricht' } }
      it { should eq([]) }
    end

    describe 'given a message with one photo' do
      let(:message) do
        {
          message: {
            # message_id: 182,
            from: {
              id: 4711,
              first_name: 'Robert',
              last_name: 'Schäfer',
              username: 'roschaefer'
              # ...
            },
            chat: {
              id: 4711
              # ...
            },
            date: 1_590_154_462,
            photo: [
              {
                file_id: 'f1',
                file_unique_id: 'fu1',
                file_size: 6293,
                width: 320,
                height: 120
              },

              {
                file_id: 'f2',
                file_unique_id: 'fu2',
                file_size: 23_388,
                width: 800,
                height: 299
              },
              {
                file_id: 'f3',
                file_unique_id: 'fu3',
                file_size: 41_585,
                width: 1280,
                height: 478
              }
            ],
            caption: 'Ich bin eine Caption'
          }
        }
      end

      it { should_not be_empty }
      it { should all(be_a(Photo)) }

      it 'calls Telegram API twice to get the download link' do
      end

      it 'chooses the largest image file for the Photo' do
      end
    end
  end

  describe '#user' do
    subject { telegram_message.user }
    let(:message) { { 'chat' => { 'id' => 42 }, 'from' => { 'id' => 47, 'username' => 'alice' } } }
    it { should be_a(User) }

    describe 'calling #save! on the user' do
      it { expect { subject.save! }.to(change { User.count }.from(0).to(1)) }

      describe 'attributes of the created user' do
        before(:each) { subject.save! }
        let(:user) { User.first }
        it { expect(user).to have_attributes(telegram_chat_id: 42, telegram_id: 47, username: 'alice') }
      end

      describe 'given an existing but outdated user record' do
        before(:each) { create(:user, telegram_id: 47, username: 'bob') }
        it { expect { subject.save! }.to(change { User.first.username }.from('bob').to('alice')) }
      end
    end
  end
end
