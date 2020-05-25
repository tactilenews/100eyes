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
      let(:message) { { caption: 'Das hier ist die Überschrift eine Fotos' } }
      it { should eq('Das hier ist die Überschrift eine Fotos') }
    end
  end

  describe '#photos' do
    subject { telegram_message.photos }
    describe 'given a message without photos' do
      let(:message) { { text: 'Ich bin eine normale Nachricht' } }
      it { should eq([]) }
    end

    describe 'given a message with one photo', vcr: { cassette_name: :photo_with_image } do
      let(:message) { message_with_photo }

      it { should_not be_empty }
      it { should all(be_a(Photo)) }

      it 'chooses the largest image' do
        photo = subject.first
        expect(photo.image.blob.byte_size).to eq(90_449)
      end
    end
  end

  describe '#reply', vcr: { cassette_name: :photo_with_image } do
    let(:request) { create(:request) }
    let(:message) { message_with_photo }
    subject { telegram_message.reply }
    it { should be_a(Reply) }
    describe 'assigning a request and calling #save! on the reply' do
      it {
        expect do
          subject.request = request
          subject.save!
        end.to(change { Reply.count }.from(0).to(1))
      }

      describe 'given the user sends a series of images as album', vcr: { cassette_name: :photo_album } do
        let(:message_with_media_group_id) { message_with_photo.merge(media_group_id: '42') }
        let(:save_reply_and_photo) do
          lambda {
            tm = TelegramMessage.new message_with_media_group_id
            reply = tm.reply
            reply.request = request
            reply.save
            reply.photos << tm.photos
          }
        end

        it { expect { 3.times { save_reply_and_photo.call } }.to(change { Reply.count }.from(0).to(1)) }
        it { expect { 3.times { save_reply_and_photo.call } }.to(change { Photo.count }.from(0).to(3)) }
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

  let(:message_with_photo) do
    { 'message_id' => 186,
      'from' =>
    { 'id' => 4711,
      'is_bot' => false,
      'first_name' => 'Robert',
      'last_name' => 'Schäfer',
      'username' => 'roschaefer',
      'language_code' => 'en' },
      'chat' =>
    { 'id' => 4711,
      'first_name' => 'Robert',
      'last_name' => 'Schäfer',
      'username' => 'roschaefer',
      'type' => 'private' },
      'date' => 1_590_173_947,
      'photo' =>
    [{ 'file_id' =>
       'AgACAgIAAxkBAAO6Xsgg-634JM6OTCBsZd9x6Iv5rbcAAtyuMRvWu0FK4BnZYCoEVwF2DQWSLgADAQADAgADbQAD8LoBAAEZBA',
       'file_unique_id' => 'AQADdg0Fki4AA_C6AQAB',
       'file_size' => 17_659,
       'width' => 213,
       'height' => 320 },
     { 'file_id' =>
       'AgACAgIAAxkBAAO6Xsgg-634JM6OTCBsZd9x6Iv5rbcAAtyuMRvWu0FK4BnZYCoEVwF2DQWSLgADAQADAgADeAAD8roBAAEZBA',
       'file_unique_id' => 'AQADdg0Fki4AA_K6AQAB',
       'file_size' => 68_574,
       'width' => 533,
       'height' => 800 },
     { 'file_id' =>
       'AgACAgIAAxkBAAO6Xsgg-634JM6OTCBsZd9x6Iv5rbcAAtyuMRvWu0FK4BnZYCoEVwF2DQWSLgADAQADAgADeQAD8boBAAEZBA',
       'file_unique_id' => 'AQADdg0Fki4AA_G6AQAB',
       'file_size' => 90_449,
       'width' => 640,
       'height' => 961 }],
      'caption' => 'A cute kitten' }
  end
end
