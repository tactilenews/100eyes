# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe TelegramAdapter::Inbound, telegram_bot: :rails do
  let(:adapter) { described_class.new(organization) }
  let(:organization) { create(:organization, telegram_bot_api_key: 'TELEGRAM_BOT_API_KEY', telegram_bot_username: 'TELEGRAM_BOT_USERNAME') }
  let(:contributor) { create(:contributor, :with_an_avatar, telegram_id: telegram_id, organization: organization) }
  let(:telegram_id) { 146_338_764 }
  let(:telegram_message) do
    { 'chat' => { 'id' => 42 },
      'from' => { 'id' => telegram_id } }
  end
  let(:bot) { Telegram.bots[organization.id] }

  before { contributor }

  before do
    Telegram.reset_bots
    Telegram::Bot::ClientStub.stub_all!(false)
    Telegram.bots_config = {
      organization.id => {
        # must be the filtered values from /spec/vcr_setup.rb
        token: organization.telegram_bot_api_key,
        username: organization.telegram_bot_username
      }
    }
  end

  after do
    Telegram::Bot::ClientStub.stub_all!(true)
    Telegram.reset_bots
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

      describe 'given the payload does not have a caption nor text' do
        let(:telegram_message) { telegram_message_from_spammer }

        it { should be_nil }

        describe 'when UNKNOWN_CONTRIBUTOR is registered' do
          it do
            expect do |block|
              adapter.on(TelegramAdapter::UNKNOWN_CONTRIBUTOR, &block)
              adapter.consume(telegram_message)
            end.to yield_control
          end
        end
      end
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
          it { expect { subject.call }.to change { ActiveStorage::Attachment.where(record_type: 'Message::File').count }.from(0).to(1) }
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

          it { expect { subject.call }.to(change { Message.count }.from(0).to(1)) }

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
        context 'but has no `avatar` attached', vcr: { cassette_name: :avatar_url_and_download_file } do
          let(:contributor) { create(:contributor, telegram_id: telegram_id, organization: organization) }
          let(:telegram_message) do
            { 'chat' => { 'id' => 42 }, 'from' => { 'id' => contributor.telegram_id }, 'text' => 'Do not save me without text' }
          end
          it { expect { subject.save! }.to(change { contributor.reload.avatar.attached? }.from(false).to(true)) }

          describe 'avatar filename' do
            before { subject.save! }
            it { expect(contributor.reload.avatar.attachment.blob.filename.to_s).to eq('file_7.jpg') }
          end

          context 'sanity-check: if contributor has no telegram_id' do
            let(:telegram_id) { nil }
            it { expect { subject.save! }.not_to(change { contributor.reload.avatar.attached? }.from(false)) }
          end

          context 'if contributor has no profile photo on Telegram' do
            before do
              mock_response = { result: { photos: [] } }
              allow(organization.telegram_bot).to receive(:get_user_profile_photos).and_return(mock_response)
            end
            it { expect { subject.save! }.not_to(change { contributor.reload.avatar.attached? }.from(false)) }
          end
        end

        context 'but `username` is outdated' do
          let(:contributor) { create(:contributor, :with_an_avatar, telegram_id: 42, username: 'bob', organization: organization) }
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

  let(:telegram_message_from_spammer) do
    {
      message_id: 25,
      from: {
        id: 5_521_147_309,
        is_bot: false,
        # rubocop:disable Layout/LineLength
        first_name: "\u0423\u043c\u0438\u0440\u0430\u044e \u0438 \u0432\u0441\u0435 \u0440\u0430\u0434\u044b \u043a\u0430\u043a \u0438 \u044f)",
        # rubocop:enable  Layout/LineLength
        username: 'Annazollo'
      },
      chat: {
        id: -1_001_597_054_590,
        title: "Milfa \u043e\u0431\u0449\u0435\u043d\u0438\u044f \u0447\u0430\u0442",
        username: 'milfadanil',
        type: 'supergroup'
      },
      date: 1_693_849_886,
      new_chat_participant: {
        id: 5_829_883_840,
        is_bot: true,
        first_name: 'Wir sind Potsdam',
        username: 'MAZ_Potsdam_Bot'
      },
      new_chat_member: {
        id: 5_829_883_840,
        is_bot: true,
        first_name: 'Wir sind Potsdam',
        username: 'MAZ_Potsdam_Bot'
      },
      new_chat_members: [
        {
          id: 5_829_883_840,
          is_bot: true,
          first_name: 'Wir sind Potsdam',
          username: 'MAZ_Potsdam_Bot'
        }
      ]
    }
  end
end
