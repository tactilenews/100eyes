# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  it 'is by default sorted in reverse chronological order' do
    oldest_message = create(:message, created_at: 2.hours.ago)
    newest_message = create(:message, created_at: 1.hour.ago)

    expect(described_class.first).to eq(newest_message)
    expect(described_class.last).to eq(oldest_message)
  end

  describe '#contributor' do
    let(:contributor) { create(:contributor) }
    subject { message.contributor }

    describe 'with sender' do
      let(:message) { create(:message, sender: contributor) }
      it { should eql(contributor) }
    end

    context 'with recipient' do
      let(:message) { create(:message, :with_recipient, recipient: contributor) }
      it { should eql(contributor) }
    end
  end

  describe '#reply?' do
    subject { message.reply? }
    describe 'message has a sender' do
      let(:message) { create(:message, sender: create(:contributor)) }
      it { should be(true) }
    end

    describe 'message has no sender' do
      let(:message) { create(:message, sender: nil) }
      it { should be(false) }
    end
  end

  describe 'deeplinks' do
    let(:contributor) { create(:contributor, id: 7) }
    let(:request) { create(:request, id: 6) }
    let(:message) { create(:message, request: request, **params) }

    describe '#conversation_link' do
      subject { message.conversation_link }

      describe 'given a recipient' do
        let(:params) { { sender: nil, recipient: contributor } }
        it { should eq('/contributors/7/requests/6') }
      end

      describe 'given a sender' do
        let(:params) { { recipient: nil, sender: contributor } }
        it { should eq('/contributors/7/requests/6') }
      end
    end

    describe '#chat_message_link' do
      subject { message.chat_message_link }
      let(:params) { { id: 8, recipient: nil, sender: contributor } }
      it { should eq('/contributors/7/requests/6#chat-row-8') }
    end
  end

  describe 'validations' do
    let(:message) { build(:message, sender: nil) }
    subject { message }
    describe '#raw_data' do
      describe 'missing' do
        before(:each) { message.raw_data = nil }
        it { should be_valid }
        describe 'but with a given sender' do
          before(:each) { message.sender = build(:contributor) }
          it { should_not be_valid }
        end
      end
    end
  end

  describe '::renew!', vcr: { cassette_name: :photo_album } do
    subject { -> { Message.renew!(message) } }

    describe 'given an old message with unparsed data of a encoded Email' do
      let(:mail) do
        mail = Mail.new do |m|
          m.from 'contributor@example.org'
          m.to '100eyes@example.org'
          m.subject 'This is a test email'
        end
        mail.text_part = 'This is the new stuff'
        mail
      end

      let(:message) do
        message = build(:message, sender: create(:contributor))
        message.raw_data.attach(
          io: StringIO.new(mail.encoded),
          filename: 'unparsed.eml',
          content_type: 'message/rfc822'
        )
        message.text = nil
        message.save!
        message
      end

      it { should change { message.text }.from(nil).to('This is the new stuff') }

      describe 'given an old message with unparsed data of a Telegram API call' do
        it { should change { message.text }.from(nil).to('This is the new stuff') }

        describe 'even if there are multiple Telegram API calls with photos' do
          let(:message) do
            message = build(:message, sender: create(:contributor))
            3.times do
              message.raw_data.attach(
                io: StringIO.new(JSON.generate(telegram_message_with_photo)),
                filename: 'unparsed.json',
                content_type: 'application/json'
              )
            end
            message.text = nil
            message.save!
            message
          end

          before(:each) { message }
          it { should change { message.photos.count }.from(0).to(3) }
          it { should_not(change { Message.count }) }
        end
      end
    end
  end

  describe '#before_create' do
    let(:message) { create(:message, sender: nil, recipient: recipient) }
    describe 'given a recipient with telegram' do
      let(:recipient) { create(:contributor, telegram_chat_id: 47, telegram_id: 11) }
      describe '#blocked' do
        subject { message.blocked }
        it { should be(false) }
        describe 'but if contributor blocked the telegram bot' do
          before(:each) { allow(Telegram.bot).to receive(:send_message).and_raise(Telegram::Bot::Forbidden) }
          it { should be(true) }
        end
      end
    end
  end

  let(:telegram_message_with_photo) do
    {
      'message_id' => 186,
      'from' => {
        'id' => 4711,
        'is_bot' => false,
        'first_name' => 'Robert',
        'last_name' => 'Schäfer',
        'username' => 'roschaefer',
        'language_code' => 'en'
      },
      'chat' => {
        'id' => 4711,
        'first_name' => 'Robert',
        'last_name' => 'Schäfer',
        'username' => 'roschaefer',
        'type' => 'private'
      },
      'date' => 1_590_173_947,
      'caption' => 'A cute kitten',
      'photo' => [{
        'file_id' => 'AgACAgIAAxkBAAO6Xsgg-634JM6OTCBsZd9x6Iv5rbcAAtyuMRvWu0FK4BnZYCoEVwF2DQWSLgADAQADAgADbQAD8LoBAAEZBA',
        'file_unique_id' => 'AQADdg0Fki4AA_C6AQAB',
        'file_size' => 17_659,
        'width' => 213,
        'height' => 320
      }, {
        'file_id' => 'AgACAgIAAxkBAAO6Xsgg-634JM6OTCBsZd9x6Iv5rbcAAtyuMRvWu0FK4BnZYCoEVwF2DQWSLgADAQADAgADeAAD8roBAAEZBA',
        'file_unique_id' => 'AQADdg0Fki4AA_K6AQAB',
        'file_size' => 68_574,
        'width' => 533,
        'height' => 800
      }, {
        'file_id' => 'AgACAgIAAxkBAAO6Xsgg-634JM6OTCBsZd9x6Iv5rbcAAtyuMRvWu0FK4BnZYCoEVwF2DQWSLgADAQADAgADeQAD8boBAAEZBA',
        'file_unique_id' => 'AQADdg0Fki4AA_G6AQAB',
        'file_size' => 90_449,
        'width' => 640,
        'height' => 961
      }]
    }
  end
end
