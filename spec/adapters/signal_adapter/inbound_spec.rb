# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalAdapter::Inbound do
  let(:adapter) { described_class.new }
  let(:signal_message) do
    {
      envelope: {
        source: '+4912345789',
        sourceDevice: 2,
        timestamp: 1_626_708_555_697,
        dataMessage: {
          timestamp: 1_626_708_555_697,
          message: 'Hello 100eyes',
          expiresInSeconds: 0,
          viewOnce: false,
          mentions: [],
          attachments: [],
          contacts: []
        }
      }
    }
  end

  let(:receipt_message) do
    {
      envelope: {
        source: '+4912345789',
        sourceDevice: 1,
        timestamp: 1_626_711_330_462,
        receiptMessage: {
          when: 1_626_711_330_462,
          isDelivery: true,
          isRead: false,
          timestamps: [
            1_626_711_326_111
          ]
        }
      }
    }
  end

  let(:signal_message_with_attachment) do
    {
      envelope: {
        source: '+4912345789',
        sourceDevice: 2,
        timestamp: 1_626_708_555_697,
        dataMessage: {
          timestamp: 1_626_708_555_697,
          message: 'Hello 100eyes',
          expiresInSeconds: 0,
          viewOnce: false,
          mentions: [],
          attachments: [{
                contentType: "audio/aac",
                filename: "Sprachnachricht.m4a",
                id: "YBAdllZwFGbAyFSMKotg",
                size: 89549
            }],
          contacts: []
        }
      }
    }
  end

  let(:signal_message_with_multiple_attachments) do
    {
      envelope: {
        source: '+4912345789',
        sourceDevice: 2,
        timestamp: 1_626_708_555_697,
        dataMessage: {
          timestamp: 1_626_708_555_697,
          message: 'Hello 100eyes',
          expiresInSeconds: 0,
          viewOnce: false,
          mentions: [],
          attachments: [{
                        contentType: "image/jpeg",
                        filename: "signal-2021-09.jpeg",
                        id: "l6p45gFMqagnxXT_St4V",
                        size: 145078
                    },
                    {
                        contentType: "image/jpeg",
                        filename: "signal-2021-09.jpeg",
                        id: "S8lmoTAkH5M5Ad0BEarh",
                        size: 115809
                    }],
          contacts: []
        }
      }
    }
  end


  before { contributor }
  let(:contributor) { create(:contributor, id: 4711, signal_phone_number: '+4912345789') }

  describe '#consume' do
    let(:message) do
      adapter.consume(signal_message) do |message|
        return message
      end
    end

    describe '|message| block argument' do
      subject { message }
      it { should be_a(Message) }

      context 'contributor not found' do
        let(:contributor) { create(:contributor, signal_phone_number: '+495555555') }

        it { should be(nil) }
      end

      context 'receipt message' do
        let(:signal_message) { receipt_message }

        it { should be(nil) }
      end
    end

    describe '|message|text' do
      subject { message.text }

      context 'given a signal_message with a `message`' do
        it { should eq('Hello 100eyes') }
      end

      context 'given a signal_message without a `message` and with attachment' do
        let(:signal_message) { signal_message_with_attachment }
        before { signal_message[:envelope][:dataMessage][:message] = nil }
        it { should be(nil) }
      end
    end

    describe '|message|raw_data' do
      subject { message.raw_data }
      it { should be_attached }
    end

    describe '#sender' do
      subject { message.sender }

      it { should eq(Contributor.find(4711)) }
    end

    describe '|message|files' do
      let(:signal_message) { signal_message_with_attachment }

      describe 'handling different content types' do
        let(:file) { message.files.first }
        subject { file.attachment }

        context 'given an audio file' do
          before { signal_message[:envelope][:dataMessage][:attachments][0][:contentType] = 'audio/aac' }
          
          it { should be_attached }

          it 'preserves the content_type' do
            expect(subject.blob.content_type).to eq('audio/aac')
          end
        end

        context 'given an image file' do
          before { signal_message[:envelope][:dataMessage][:attachments][0][:contentType] = 'image/jpeg' }
          it { should be_attached }

          it 'preserves the content_type' do
            expect(subject.blob.content_type).to eq('image/jpeg')
          end
        end

        context 'given a gif' do
          before { signal_message[:envelope][:dataMessage][:attachments][0][:contentType] = 'image/gif' }
          it { should be_attached }

          it 'preserves the content_type' do
            expect(subject.blob.content_type).to eq('image/gif')
          end
        end
      end

    context 'given a message with multiple attached images' do
      let(:signal_message) { signal_message_with_multiple_attachments }
      it 'should store all files' do
        expect(message.files[0].attachment).to be_attached
        expect(message.files[1].attachment).to be_attached
      end
    end 
  end

    context 'given a message with text and an attachment' do
      let(:signal_message) { signal_message_with_attachment }

      it 'should contain text and file' do
        expect(message.text).to eq('Hello 100eyes')
        expect(message.files.first.attachment).to be_attached
      end
    end 
  end

  describe '#on' do

    describe 'UNKNOWN_CONTRIBUTOR' do
      let(:unknown_contributor_callback) { spy('unknown_contributor_callback') }
      
      before do
        adapter.on(SignalAdapter::UNKNOWN_CONTRIBUTOR) do |signal_phone_number|
          unknown_contributor_callback.call(signal_phone_number)
        end
      end

      subject do
        adapter.consume(signal_message)
        unknown_contributor_callback
      end

      describe 'if the sender is a contributor ' do
        it { should_not have_received(:call) }
      end

      describe 'if the sender is unknown' do
        before { signal_message[:envelope][:source] = '+4955443322' }
        it { should have_received(:call).with('+4955443322') }
      end
    end

    describe 'UNKNOWN_CONTENT' do
      let(:unknown_content_callback) { spy('unknown_content_callback') }
      
      before do 
        adapter.on(SignalAdapter::UNKNOWN_CONTENT) do |contributor| 
          unknown_content_callback.call(contributor)
        end
      end

      subject do
        adapter.consume(signal_message)
        unknown_content_callback
      end

      context 'if the message is a plaintext message' do
        it { should_not have_received(:call) }
      end

      context 'if the message contains a contact' do
        before { signal_message[:envelope][:dataMessage][:contacts] = ['Käptn Blaubär'] }
        it { should have_received(:call).with(contributor) }
      end

      context 'if the message contains a reaction' do
        before do 
          signal_message[:envelope][:dataMessage][:reaction] = {
            "emoji": "❤️",
            "targetAuthor": "+4915100000000",
            "targetSentTimestamp": 1630442783119,
            "isRemove": false
          }
        end
        it { should have_received(:call).with(contributor) }
      end

      context 'if the message contains a sticker' do
        before do 
          signal_message[:envelope][:dataMessage][:sticker] = {
            "packId": "zMiaBdwHeFa1c1HpBpeXbA==",
            "packKey": "RXMOYPCdVWYRUiN0RTemt9nqmc7qy3eh+9aAG5YH+88=",
            "stickerId": 3
          }
        end
        it { should have_received(:call).with(contributor) }
      end

      context 'if the message contains a mention' do
        before { signal_message[:envelope][:dataMessage][:mentions] = ['everyone'] }
        it { should have_received(:call).with(contributor) }
      end

      context 'if the message contains supported attachments' do
        let(:signal_message) { signal_message_with_attachment }
        it { should_not have_received(:call) }
      end

      context 'if the message contains unsupported attachments' do
        let(:signal_message) { signal_message_with_attachment }
        before { signal_message[:envelope][:dataMessage][:attachments][0][:contentType] = ['application/pdf'] }
        it { should have_received(:call).with(contributor) }
      end
    end
  end
end
