# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe TelegramAdapter::Inbound, telegram_bot: :rails do
  let(:adapter) { described_class.new }
  let(:contributor) { create(:contributor, telegram_id: telegram_id) }
  let(:telegram_id) { 47 }
  let(:telegram_message) { { 'chat' => { 'id' => 42 }, 'from' => { 'id' => 47 } } }
  before { contributor }

  describe '#avatar_url', vcr: { cassette_name: :avatar_url } do
    before do
      allow(Telegram.bot).to receive(:get_user_profile_photos).and_return(get_user_profile_photos)
      allow(Telegram.bot).to receive(:get_file).with(file_id: '<largest_file_id>').and_return(get_file)
    end

    let(:telegram_id) { 4711 }
    subject { adapter.avatar_url(contributor) }
    let(:expected_url) { 'https://api.telegram.org/file/botTOKEN/photos/file_7.jpg' }
    it { is_expected.to eq(expected_url) }

    context 'of a contributor without `telegram_id`' do
      let(:telegram_id) { nil }
      it { is_expected.to be(nil) }
    end
  end

  describe '#consume' do
    let(:message) do
      adapter.consume(telegram_message) do |message|
        return message
      end
    end

    describe '|message| block argument' do
      subject { message }
      it { should be_a(Message) }
    end

    describe '|message|text' do
      subject { message.text }

      describe 'given a telegram_message with a `text` attribute' do
        before { telegram_message['text'] = 'Ich bin eine normale Nachricht' }
        it { should eq('Ich bin eine normale Nachricht') }
      end

      describe 'given a photo with a `caption`' do
        before { telegram_message['caption'] = 'Das hier ist die Überschrift eine Fotos' }
        it { should eq('Das hier ist die Überschrift eine Fotos') }
      end
    end

    describe '|message|raw_data' do
      subject { message.raw_data }
      describe 'given a text message' do
        before { telegram_message['text'] = 'Ich bin eine normale Nachricht' }
        it { should be_attached }
      end
    end

    describe '|message|file' do
      subject { message.file }

      describe 'given a text message' do
        before { telegram_message['text'] = 'Ich bin eine normale Nachricht' }
        it { should be_nil }
      end

      describe 'given a voice message', vcr: { cassette_name: :voice_message } do
        before { create(:contributor, telegram_id: 875_171_743) }
        let(:telegram_message) { message_with_voice }

        describe 'attachment' do
          subject { message.file.attachment }
          it { should be_attached }
        end

        describe 'saving the message' do
          subject do
            lambda do
              message.request = create(:request)
              message.save!
            end
          end
          it { should change { ActiveStorage::Attachment.where(record_type: 'Message::File').count }.from(0).to(1) }
        end
      end
    end

    describe '|message|photos' do
      subject { message.photos }
      describe 'given a message without photos' do
        before { message['text'] = 'Ich bin eine normale Nachricht' }
        it { should eq([]) }
      end

      describe 'given a message with multiple photos', vcr: { cassette_name: :photo_with_image } do
        before { create(:contributor, telegram_id: 875_171_743) }
        let(:telegram_message) { message_with_photo }

        it { should_not be_empty }
        it { should all(be_a(Photo)) }

        it 'chooses the largest image' do
          photo = subject.first
          expect(photo.attachment.blob.byte_size).to eq(134_866)
        end

        describe 'assigning a request and calling #save! on the message' do
          let(:request) { create(:request) }
          let(:subject) do
            lambda do
              adapter.consume(telegram_message) do |m|
                m.request = request
                m.save!
              end
            end
          end

          it { is_expected.to(change { Message.count }.from(0).to(1)) }

          describe 'given the contributor sends a series of images as album', vcr: { cassette_name: :photo_album } do
            let(:telegram_message) { message_with_photo.merge(media_group_id: '42') }
            it { expect { 3.times { subject.call } }.to(change { Message.count }.from(0).to(1)) }
            it { expect { 3.times { subject.call } }.to(change { Photo.count }.from(0).to(3)) }
          end
        end
      end
    end

    describe '|message|unknown_content' do
      subject { message.unknown_content }
      describe 'given a telegram api message' do
        before { create(:contributor, telegram_id: 875_171_743) }

        describe 'with a photo', vcr: { cassette_name: :photo_with_image } do
          let(:telegram_message) { message_with_photo }
          it { should be(false) }
        end

        describe 'with a voice message', vcr: { cassette_name: :voice_message } do
          let(:telegram_message) { message_with_voice }
          it { should be(false) }
        end

        describe 'message with a document', vcr: { cassette_name: :photo_with_image } do
          let(:telegram_message) { message_with_photo.merge({ document: 'something' }) }
          it { should be(true) }
        end
      end
    end

    describe '#sender' do
      subject { message.sender }

      context 'known sender, but outdated contributor record' do
        let(:telegram_message) { { 'chat' => { 'id' => 42 }, 'from' => { 'id' => contributor.telegram_id, 'username' => 'alice' } } }
        let(:contributor) { create(:contributor, telegram_id: 42, username: 'bob') }

        it { expect { subject.save! }.to(change { contributor.reload.username }.from('bob').to('alice')) }
      end
    end
  end

  let(:message_with_voice) do
    { 'message_id' => 44,
      'from' =>
    { 'id' => 875_171_743,
      'is_bot' => false,
      'first_name' => 'Matthew',
      'last_name' => 'Rider',
      'username' => 'matthew_rider',
      'language_code' => 'en' },
      'chat' =>
    { 'id' => 875_171_743,
      'first_name' => 'Matthew',
      'last_name' => 'Rider',
      'username' => 'matthew_rider',
      'type' => 'private' },
      'date' => 1_605_027_501,
      'voice' =>
    { 'duration' => 4,
      'mime_type' => 'audio/ogg',
      'file_id' =>
    'AwACAgIAAxkBAAMsX6rGrbnRVqtmAdt2vtmhT4_r1-MAAgYLAAIHD1hJ1hEoFDaF0TUeBA',
      'file_unique_id' => 'AgADBgsAAgcPWEk',
      'file_size' => 15_988 } }
  end

  let(:message_with_photo) do
    { 'message_id' => 48,
      'from' =>
    { 'id' => 875_171_743,
      'is_bot' => false,
      'first_name' => 'Matthew',
      'last_name' => 'Rider',
      'username' => 'matthew_rider',
      'language_code' => 'en' },
      'chat' =>
    { 'id' => 875_171_743,
      'first_name' => 'Matthew',
      'last_name' => 'Rider',
      'username' => 'matthew_rider',
      'type' => 'private' },
      'date' => 1_605_028_446,
      'media_group_id' => '12840227575408058',
      'photo' =>
     [{ 'file_id' =>
     'AgACAgIAAxkBAAMwX6rKXsVDydXIHrEryL-TGemMtlcAAiuxMRsHD1hJKApaFpocC4skq-uXLgADAQADAgADbQAD6dkCAAEeBA',
        'file_unique_id' => 'AQADJKvrly4AA-nZAgAB',
        'file_size' => 17_617,
        'width' => 320,
        'height' => 240 },
      { 'file_id' =>
      'AgACAgIAAxkBAAMwX6rKXsVDydXIHrEryL-TGemMtlcAAiuxMRsHD1hJKApaFpocC4skq-uXLgADAQADAgADeAAD6tkCAAEeBA',
        'file_unique_id' => 'AQADJKvrly4AA-rZAgAB',
        'file_size' => 80_847,
        'width' => 800,
        'height' => 600 },
      { 'file_id' =>
      'AgACAgIAAxkBAAMwX6rKXsVDydXIHrEryL-TGemMtlcAAiuxMRsHD1hJKApaFpocC4skq-uXLgADAQADAgADeQAD59kCAAEeBA',
        'file_unique_id' =>
      'AQADJKvrly4AA-fZAgAB',
        'file_size' => 134_866,
        'width' => 1280,
        'height' => 960 }] }
  end

  let(:get_user_profile_photos) do
    { 'ok' => true,
      'result' =>
  { 'total_count' => 1,
    'photos' =>
    [[{ 'file_id' =>
        'AgACAgIAAxUAAWC4DHtVI8MrfOwy9wJFLT7hZx-SAAJRqDEbzPO4CHVJ3MNErvhcVrWrDgAEAQADAgADYQAD7UcAAh8E',
        'file_unique_id' => 'AQADVrWrDgAE7UcAAg',
        'file_size' => 7455,
        'width' => 160,
        'height' => 160 },
      { 'file_id' =>
        'AgACAgIAAxUAAWC4DHtVI8MrfOwy9wJFLT7hZx-SAAJRqDEbzPO4CHVJ3MNErvhcVrWrDgAEAQADAgADYgAD7kcAAh8E',
        'file_unique_id' => 'AQADVrWrDgAE7kcAAg',
        'file_size' => 21_268,
        'width' => 320,
        'height' => 320 },
      { 'file_id' =>
        '<largest_file_id>',
        'file_unique_id' => 'AQADVrWrDgAE70cAAg',
        'file_size' => 58_194,
        'width' => 640,
        'height' => 640 }]] } }
  end

  let(:get_file) do
    { 'ok' => true,
      'result' =>
  { 'file_id' =>
    'AgACAgIAAxUAAWC4DHtVI8MrfOwy9wJFLT7hZx-SAAJRqDEbzPO4CHVJ3MNErvhcVrWrDgAEAQADAgADYwAD70cAAh8E',
    'file_unique_id' => 'AQADVrWrDgAE70cAAg',
    'file_size' => 58_194,
    'file_path' => 'photos/file_7.jpg' } }
  end
end
