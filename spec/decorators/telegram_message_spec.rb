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

  describe '#voice' do
    subject { telegram_message.voice }

    describe 'given a text message' do
      let(:message) { { text: 'Ich bin eine normale Nachricht' } }

      it { should be_nil }
      describe 'saving the message' do
        subject { telegram_message.message.raw_data }
        it { should be_attached }
      end
    end

    describe 'given a voice message', vcr: { cassette_name: :voice_message } do
      let(:message) { message_with_voice }

      describe 'attachment' do
        subject { telegram_message.voice.attachment }
        it { should be_attached }
      end

      describe 'saving the message' do
        subject do
          lambda do
            telegram_message.message.request = create(:request)
            telegram_message.message.save!
          end
        end
        it { should change { ActiveStorage::Attachment.where(record_type: 'Voice').count }.from(0).to(1) }
      end
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
        expect(photo.attachment.blob.byte_size).to eq(90_449)
      end
    end
  end

  describe '#message', vcr: { cassette_name: :photo_with_image } do
    let(:request) { create(:request) }
    let(:message) { message_with_photo }
    subject { telegram_message.message }
    it { should be_a(Message) }

    describe 'assigning a request and calling #save! on the message' do
      it {
        expect do
          subject.request = request
          subject.save!
        end.to(change { Message.count }.from(0).to(1))
      }

      describe 'given the contributor sends a series of images as album', vcr: { cassette_name: :photo_album } do
        let(:telegram_message_with_media_group_id) { message_with_photo.merge(media_group_id: '42') }
        let(:save_message_and_photo) do
          lambda {
            tm = TelegramMessage.new telegram_message_with_media_group_id
            message = tm.message
            message.request = request
            message.save
          }
        end

        it { expect { 3.times { save_message_and_photo.call } }.to(change { Message.count }.from(0).to(1)) }
        it { expect { 3.times { save_message_and_photo.call } }.to(change { Photo.count }.from(0).to(3)) }
      end
    end

    describe '.unknown_content' do
      subject { telegram_message.message.unknown_content }
      describe 'given a telegram api message' do
        describe 'with a photo' do
          let(:message) { message_with_photo }
          it { should be(false) }
        end

        describe 'with a voice message', vcr: { cassette_name: :voice_message } do
          let(:message) { message_with_voice }
          it { should be(false) }
        end

        describe 'message with a document' do
          let(:message) { message_with_photo.merge({ document: 'something' }) }
          it { should be(true) }
        end
      end
    end
  end

  describe '#sender' do
    subject { telegram_message.sender }
    let(:message) { { 'chat' => { 'id' => 42 }, 'from' => { 'id' => 47, 'username' => 'alice' } } }
    it { should be_a(Contributor) }

    describe 'calling #save! on the sender' do
      it { expect { subject.save! }.to(change { Contributor.count }.from(0).to(1)) }

      describe 'attributes of the created contributor' do
        before(:each) { subject.save! }
        let(:contributor) { Contributor.first }
        it { expect(contributor).to have_attributes(telegram_chat_id: 42, telegram_id: 47, username: 'alice') }
      end

      describe 'given an existing but outdated contributor record' do
        before(:each) { create(:contributor, telegram_id: 47, username: 'bob') }
        it { expect { subject.save! }.to(change { Contributor.first.username }.from('bob').to('alice')) }
      end
    end
  end

  let(:message_with_voice) do
    { 'message_id' => 429,
      'from' =>
    { 'id' => 146_338_764,
      'is_bot' => false,
      'first_name' => 'Robert',
      'last_name' => 'Schäfer',
      'username' => 'roschaefer',
      'language_code' => 'en' },
      'chat' =>
    { 'id' => 146_338_764,
      'first_name' => 'Robert',
      'last_name' => 'Schäfer',
      'username' => 'roschaefer',
      'type' => 'private' },
      'date' => 1_600_880_655,
      'voice' =>
    { 'duration' => 5,
      'mime_type' => 'audio/ogg',
      'file_id' =>
    'AwACAgIAAxkBAAIBrV9rgA6yx0OmgWjHN7kPjT8EstJ5AAMKAAINfWFLG7ifovFsufMbBA',
      'file_unique_id' => 'AgAECgACDX1hSw',
      'file_size' => 39_368 } }
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
