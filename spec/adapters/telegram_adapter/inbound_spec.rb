# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe TelegramAdapter::Inbound, telegram_bot: :rails do
  let(:adapter) { described_class.new }
  let(:contributor) { create(:contributor, :with_an_avatar, telegram_id: telegram_id) }
  let(:telegram_id) { 146_338_764 }
  let(:telegram_message) do
    { 'chat' => { 'id' => 42 },
      'from' => { 'id' => telegram_id } }
  end
  before { contributor }

  before(:all) do
    Telegram::Bot::ClientStub.stub_all!(false)
  end

  before do
    config = {
      # must be the filtered values from /spec/vcr_setup.rb
      token: ENV['TELEGRAM_BOT_API_KEY'] || 'TELEGRAM_BOT_API_KEY',
      username: ENV['TELEGRAM_BOT_USERNAME'] || 'TELEGRAM_BOT_USERNAME'
    }
    bot = Telegram::Bot::Client.wrap(config, id: :default)
    allow(Telegram).to receive(:bot).and_return(bot)
  end

  after(:all) do
    Telegram::Bot::ClientStub.stub_all!(true)
  end

  describe '#avatar_url', vcr: { cassette_name: :avatar_url_and_download_file } do
    subject { adapter.avatar_url(contributor) }
    let(:expected_url) { Regexp.new([Regexp.quote('https://api.telegram.org/file/bot'), '.*', Regexp.quote('/photos/file_7.jpg')].join) }
    specify { expect(subject.to_s).to match(expected_url) }

    context 'of a contributor without `telegram_id`' do
      let(:telegram_id) { nil }
      it { is_expected.to be(nil) }
    end

    context 'if contributor has no profile photo' do
      before do
        mock_response = { result: { photos: [] } }
        allow(Telegram.bot).to receive(:get_user_profile_photos).and_return(mock_response)
      end
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

      before { telegram_message['text'] = 'Do not save me without text' }
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

    describe '|message|files' do
      subject { message.files }

      describe 'given a text message' do
        before { telegram_message['text'] = 'Ich bin eine normale Nachricht' }
        it { should eq([]) }
      end

      describe 'given a voice message', vcr: { cassette_name: :voice_message } do
        let(:telegram_message) { message_with_voice }

        describe 'attachment' do
          let(:file) { message.files.first }
          subject { file.attachment }
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
        before { telegram_message['text'] = 'Ich bin eine normale Nachricht' }
        it { should eq([]) }
      end

      describe 'given a message with multiple photos', vcr: { cassette_name: :photo_with_image } do
        let(:telegram_message) { message_with_photo }

        it { should_not be_empty }
        it { should all(be_a(Photo)) }

        it 'chooses the largest image' do
          photo = subject.first
          expect(photo.attachment.blob.byte_size).to eq(20_852)
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

      context 'contributor exists' do
        context 'but missing `avatar_url`', vcr: { cassette_name: :avatar_url_and_download_file } do
          let(:contributor) { create(:contributor, telegram_id: telegram_id) }
          let(:telegram_message) do
            { 'chat' => { 'id' => 42 }, 'from' => { 'id' => contributor.telegram_id }, 'text' => 'Do not save me without text' }
          end
          it { expect { subject.save! }.to(change { contributor.reload.avatar.attached? }.from(false).to(true)) }
        end

        context 'but `username` is outdated' do
          let(:contributor) { create(:contributor, :with_an_avatar, telegram_id: 42, username: 'bob') }
          let(:telegram_message) do
            { 'chat' => { 'id' => 42 }, 'from' => { 'id' => contributor.telegram_id, 'username' => 'alice' },
              'text' => 'Do not save me without text' }
          end

          it { expect { subject.save! }.to(change { contributor.reload.username }.from('bob').to('alice')) }
        end
      end
    end
  end

  let(:message_with_voice) do
    { 'message_id' => 317,
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
      'date' => 1_622_727_630,
      'voice' =>
  { 'duration' => 2,
    'mime_type' => 'audio/ogg',
    'file_id' =>
    'AwACAgIAAxkBAAIBPWC4287e4Mfa9WSthwQlfrNg3GzYAAInDwACn6XJSb3eHU7xTx8MHwQ',
    'file_unique_id' => 'AgADJw8AAp-lyUk',
    'file_size' => 15_578 } }
  end

  let(:message_with_photo) do
    { 'message_id' => 313,
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
      'date' => 1_622_727_327,
      'photo' =>
  [{ 'file_id' =>
     'AgACAgIAAxkBAAIBOWC42p5o6Tg3wgtKpdoxUansjDGjAAKstDEbn6XJSRgNrAl8s3FxoaEdpC4AAwEAAwIAA3MAAyPoAQABHwQ',
     'file_unique_id' => 'AQADoaEdpC4AAyPoAQAB',
     'file_size' => 1460,
     'width' => 90,
     'height' => 90 },
   { 'file_id' =>
     'AgACAgIAAxkBAAIBOWC42p5o6Tg3wgtKpdoxUansjDGjAAKstDEbn6XJSRgNrAl8s3FxoaEdpC4AAwEAAwIAA20AAyToAQABHwQ',
     'file_unique_id' => 'AQADoaEdpC4AAyToAQAB',
     'file_size' => 15_028,
     'width' => 320,
     'height' => 320 },
   { 'file_id' =>
     'AgACAgIAAxkBAAIBOWC42p5o6Tg3wgtKpdoxUansjDGjAAKstDEbn6XJSRgNrAl8s3FxoaEdpC4AAwEAAwIAA3gAAyXoAQABHwQ',
     'file_unique_id' => 'AQADoaEdpC4AAyXoAQAB',
     'file_size' => 20_852,
     'width' => 460,
     'height' => 460 }] }
  end
end
