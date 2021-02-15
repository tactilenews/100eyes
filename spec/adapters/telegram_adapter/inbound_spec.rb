# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe TelegramAdapter::Inbound, telegram_bot: :rails do
  describe 'bounce!' do
    before { Setting.telegram_contributor_not_found_message = 'Who are you?' }
    subject { -> { dispatch_message 'Hello Bot!', { from: { id: 'whoami' } } } }
    it { should_not(change { Message.count }) }
    it { should respond_with_message 'Who are you?' }
  end

  let(:telegram_message) { described_class.new message }
  before(:each) { create(:contributor, telegram_id: 47) }

  let(:message) { { 'chat' => { 'id' => 42 }, 'from' => { 'id' => 47 } } }

  describe '.contributor_onboarding' do
    subject { telegram_message.contributor_onboarding }

    describe 'given a message with connected_website indicating user onboarding' do
      before { message['connected_website'] = Setting.application_host }

      it { is_expected.to eq(true) }
    end
  end

  describe '#text' do
    subject { telegram_message.text }

    describe 'given a message with a `text` attribute' do
      before { message['text'] = 'Ich bin eine normale Nachricht' }
      it { should eq('Ich bin eine normale Nachricht') }
    end

    describe 'given a photo with a `caption`' do
      before { message['caption'] = 'Das hier ist die Überschrift eine Fotos' }
      it { should eq('Das hier ist die Überschrift eine Fotos') }
    end
  end

  describe '#file' do
    subject { telegram_message.file }

    describe 'given a text message' do
      before { message['text'] = 'Ich bin eine normale Nachricht' }

      it { should be_nil }
      describe 'saving the message' do
        subject { telegram_message.message.raw_data }
        it { should be_attached }
      end
    end

    describe 'given a voice message', vcr: { cassette_name: :voice_message } do
      before { create(:contributor, telegram_id: 875_171_743) }
      let(:message) { message_with_voice }

      describe 'attachment' do
        subject { telegram_message.file.attachment }
        it { should be_attached }
      end

      describe 'saving the message' do
        subject do
          lambda do
            telegram_message.message.request = create(:request)
            telegram_message.message.save!
          end
        end
        it { should change { ActiveStorage::Attachment.where(record_type: 'Message::File').count }.from(0).to(1) }
      end
    end
  end

  describe '#photos' do
    subject { telegram_message.photos }
    describe 'given a message without photos' do
      before { message['text'] = 'Ich bin eine normale Nachricht' }
      it { should eq([]) }
    end

    describe 'given a message with multiple photos', vcr: { cassette_name: :photo_with_image } do
      before { create(:contributor, telegram_id: 875_171_743) }
      let(:message) { message_with_photo }

      it { should_not be_empty }
      it { should all(be_a(Photo)) }

      it 'chooses the largest image' do
        photo = subject.first
        expect(photo.attachment.blob.byte_size).to eq(134_866)
      end
    end
  end

  describe '#message', vcr: { cassette_name: :photo_with_image } do
    before { create(:contributor, telegram_id: 875_171_743) }
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
            tm = described_class.new telegram_message_with_media_group_id
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

    context 'known sender, but outdated contributor record' do
      let(:message) { { 'chat' => { 'id' => 42 }, 'from' => { 'id' => contributor.telegram_id, 'username' => 'alice' } } }
      let(:contributor) { create(:contributor, telegram_id: 42, username: 'bob') }

      it { expect { subject.save! }.to(change { contributor.reload.username }.from('bob').to('alice')) }
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
end
