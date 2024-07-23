# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalAdapter::Inbound do
  let(:adapter) { described_class.new }
  let(:signal_message) do
    {
      envelope: {
        source: '+4912345789',
        sourceNumber: '+4912345789',
        sourceUuid: 'valid_uuid',
        sourceDevice: 2,
        timestamp: 1_626_708_555_697,
        dataMessage: {
          timestamp: 1_626_708_555_697,
          message: 'Hello 100eyes',
          expiresInSeconds: 0,
          viewOnce: false
        }
      },
      account: organization.signal_server_phone_number
    }
  end

  let(:signal_message_with_uuid) do
    {
      envelope: {
        source: 'valid_uuid',
        sourceNumber: nil,
        sourceUuid: 'valid_uuid',
        sourceDevice: 2,
        timestamp: 1_626_708_555_697,
        dataMessage: {
          timestamp: 1_626_708_555_697,
          message: signal_onboarding_token,
          expiresInSeconds: 0,
          viewOnce: false
        }
      },
      account: organization.signal_server_phone_number
    }
  end

  let(:signal_receipt_message) do
    {
      envelope: {
        source: '+4912345789',
        sourceNumber: '+4912345789',
        sourceUuid: 'valid_uuid',
        sourceName: 'Signal Contributor',
        sourceDevice: 1,
        timestamp: 1_694_759_894_782,
        receiptMessage: {
          when: 1_694_759_894_782,
          isDelivery: true,
          isRead: false,
          isViewed: false,
          timestamps: [1_694_759_894_066]
        }
      },
      account: organization.signal_server_phone_number
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
          attachments: [{
            contentType: 'audio/aac',
            filename: 'Sprachnachricht.m4a',
            id: 'zuNhdpIHpRU_9Du-B4oG',
            size: 89_549
          }]
        }
      },
      account: organization.signal_server_phone_number
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
          attachments: [
            {
              contentType: 'image/jpeg',
              filename: 'signal-2021-09.jpeg',
              id: 'zuNhdpIHpRU_9Du-B4oG',
              size: 145_078
            },
            {
              contentType: 'image/jpeg',
              filename: 'signal-2021-09.jpeg',
              id: 'zuNhdpIHpRU_9Du-B4oG',
              size: 115_809
            }
          ]
        }
      },
      account: organization.signal_server_phone_number
    }
  end

  let(:signal_expire_time_message) do
    {
      envelope: {
        source: '+4912345789',
        sourceDevice: 2,
        timestamp: 1_626_708_555_697,
        dataMessage: {
          timestamp: 1_626_708_555_697,
          message: nil,
          expiresInSeconds: 3600,
          viewOnce: false
        }
      },
      account: organization.signal_server_phone_number
    }
  end

  let(:signal_remote_delete_message) do
    {
      envelope: {
        source: '+4912345789',
        sourceDevice: 2,
        timestamp: 1_626_708_555_697,
        dataMessage: {
          timestamp: 1_626_708_555_697,
          message: nil,
          expiresInSeconds: 0,
          remoteDelete: {
            timestamp: 1_630_444_176_328
          },
          viewOnce: false
        }
      },
      account: organization.signal_server_phone_number
    }
  end

  let(:signal_reaction_emoji_message) do
    {
      envelope: {
        source: '+4912345789',
        sourceDevice: 2,
        timestamp: 1_626_708_555_697,
        dataMessage: {
          timestamp: 1_626_708_555_697,
          message: nil,
          expiresInSeconds: 0,
          viewOnce: false,
          reaction: {
            emoji: '❤️',
            targetAuthor: '+4912345781',
            targetSentTimestamp: 1_630_442_783_119,
            isRemove: false
          }
        }
      },
      account: organization.signal_server_phone_number
    }
  end

  let(:signal_typing_message) do
    {
      envelope: {
        source: '+4912345789',
        sourceDevice: 1,
        timestamp: 1_648_534_000_000,
        typingMessage: {
          action: 'STARTED',
          timestamp: 1_648_534_000_000
        }
      },
      account: organization.signal_server_phone_number
    }
  end

  before do
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open)
      .with('signal-cli-config/attachments/zuNhdpIHpRU_9Du-B4oG')
      .and_return(file_fixture('signal_message_with_attachment').open)
  end

  let(:onboarding_completed_at) { Time.zone.now }
  let(:phone_number) { '+4912345789' }

  let!(:contributor) do
    create(
      :contributor,
      id: 4711,
      signal_phone_number: phone_number,
      organization: organization
    )
  end
  let(:organization) { create(:organization) }

  describe '#consume' do
    let(:message) do
      adapter.consume(signal_message) do |message|
        return message
      end
    end

    describe '|message| block argument' do
      subject { message }
      it { should be_a(Message) }

      context 'from an unknown contributor' do
        let!(:phone_number) { '+495555555' }

        it { should be(nil) }
      end

      context 'given a receipt message' do
        before { create(:message, recipient_id: contributor.id) }
        let(:signal_message) { signal_receipt_message }

        it { should be(nil) }
      end

      context 'given a typing indicator message' do
        let(:signal_message) { signal_typing_message }

        it { should be(nil) }
      end

      describe 'with ignored content' do
        context 'given an expire time message' do
          let(:signal_message) { signal_expire_time_message }
          it { should be(nil) }
        end

        context 'given a remote delete message' do
          let(:signal_message) { signal_remote_delete_message }
          it { should be(nil) }
        end

        context 'given a reaction emoji that got removed' do
          let(:signal_message) { signal_reaction_emoji_message }
          before do
            signal_reaction_emoji_message[:envelope][:dataMessage][:reaction][:isRemove] = true
          end
          it { should be(nil) }
        end
      end

      context 'given a message with text and an attachment' do
        let(:signal_message) { signal_message_with_attachment }

        it 'is expected to store message text and attached file' do
          expect(message.text).to eq('Hello 100eyes')
          expect(message.files.first.attachment).to be_attached
        end
      end

      describe 'given a message to complete onboarding' do
        let(:signal_message) { signal_message_with_uuid }
        let(:signal_uuid) { nil }
        let(:onboarding_completed_at) { nil }

        let!(:contributor) do
          create(
            :contributor,
            signal_uuid: signal_uuid,
            signal_onboarding_completed_at: onboarding_completed_at,
            signal_onboarding_token: 'NQ272QQK'
          )
        end

        context 'unknown contributor' do
          let(:signal_onboarding_token) { 'some other message' }

          it 'does not create a message' do
            expect(subject).to be(nil)
          end
        end

        context 'known contributor' do
          let(:signal_onboarding_token) { 'NQ272QQK' }

          it 'does not create a message' do
            expect(subject).to be(nil)
          end
        end
      end
    end

    describe '|message|text' do
      subject { message.text }

      context 'given a signal_message with a `message`' do
        it { should eq('Hello 100eyes') }
      end

      context 'given a signal_message without a `message` and with an attachment' do
        let(:signal_message) { signal_message_with_attachment }
        before { signal_message[:envelope][:dataMessage][:message] = nil }
        it { should be(nil) }
      end

      context 'given a reaction emoji that got added' do
        let(:signal_message) { signal_reaction_emoji_message }
        it { should eq('❤️') }
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

        context 'given an audio/mpeg file' do
          before { signal_message[:envelope][:dataMessage][:attachments][0][:contentType] = 'audio/mpeg' }

          it { should be_attached }

          it 'preserves the content_type' do
            expect(subject.blob.content_type).to eq('audio/mpeg')
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

        context 'given attachment without filename' do
          before do
            signal_message[:envelope][:dataMessage][:attachments][0][:contentType] = 'image/jpeg'
            signal_message[:envelope][:dataMessage][:attachments][0][:filename] = nil
          end

          it { should be_attached }

          it 'sets a fallback filename based on mime type' do
            expect(subject.filename.to_s).to eq('attachment.jpeg')
          end
        end
      end

      context 'given a message with multiple attached images' do
        let(:signal_message) { signal_message_with_multiple_attachments }
        it 'is expected to store all files' do
          expect(message.files[0].attachment).to be_attached
          expect(message.files[1].attachment).to be_attached
        end
      end
    end

    context 'given the keyword Abbestellen' do
      subject { message }
      before { signal_message[:envelope][:dataMessage][:message] = 'Abbestellen' }

      it 'does not create a message' do
        expect { subject }.not_to change(Message, :count)
      end
    end
  end

  describe '#on' do
    describe 'CONNECT' do
      let(:connect_callback) { spy('connect_callback') }
      let(:signal_message) { signal_message_with_uuid }
      let(:signal_uuid) { signal_message.dig(:envelope, :sourceUuid) }

      let!(:contributor) { create(:contributor, signal_onboarding_token: 'NQ272QQK', organization: organization) }

      before do
        adapter.on(SignalAdapter::CONNECT) do |contributor, signal_uuid, organization|
          connect_callback.call(contributor, signal_uuid, organization)
        end
      end

      subject do
        adapter.consume(signal_message)
        connect_callback
      end

      context 'if the sender is unknown' do
        let(:signal_onboarding_token) { 'whatever message' }
        it { should_not have_received(:call) }
      end

      context 'if the sender is a contributor with incomplete onboarding' do
        let(:signal_onboarding_token) { 'NQ272QQK' }
        it { should have_received(:call).with(contributor, signal_uuid, organization) }
      end
    end

    describe 'UNKNOWN_CONTRIBUTOR' do
      let(:unknown_contributor_callback) { spy('unknown_contributor_callback') }
      let(:signal_message) { signal_message_with_uuid }
      let(:source) { signal_message.dig(:envelope, :source) }
      let!(:contributor) { create(:contributor, signal_onboarding_token: 'NQ272QQK') }

      before do
        adapter.on(SignalAdapter::UNKNOWN_CONTRIBUTOR) do |source|
          unknown_contributor_callback.call(source)
        end
      end

      subject do
        adapter.consume(signal_message)
        unknown_contributor_callback
      end

      context 'if the sender is unknown' do
        let(:signal_onboarding_token) { 'whatever message' }
        it { should have_received(:call).with(source) }
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

      context 'if the message contains a sticker' do
        before do
          signal_message[:envelope][:dataMessage][:sticker] = {
            packId: 'zMiaBdwHeFa1c1HpBpeXbA==',
            packKey: 'RXMOYPCdVWYRUiN0RTemt9nqmc7qy3eh+9aAG5YH+88=',
            stickerId: 3
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

    describe 'UNSUBSCRIBE_CONTRIBUTOR' do
      let(:unsubscribe_contributor_callback) { spy('unsubscribe_contributor_callback') }

      before do
        adapter.on(SignalAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
          unsubscribe_contributor_callback.call(contributor)
        end
      end

      subject do
        adapter.consume(signal_message)
        unsubscribe_contributor_callback
      end

      context 'any text other than the keyword Abbestellen' do
        it { is_expected.not_to have_received(:call) }
      end

      context 'with keyword Abbestellen' do
        before { signal_message[:envelope][:dataMessage][:message] = 'Abbestellen' }

        it { is_expected.to have_received(:call) }
      end
    end

    describe 'RESUBSCRIBE_CONTRIBUTOR' do
      let(:resubscribe_contributor_callback) { spy('resubscribe_contributor_callback') }

      before do
        contributor.update!(unsubscribed_at: 1.week.ago)
        adapter.on(SignalAdapter::RESUBSCRIBE_CONTRIBUTOR) do |contributor|
          resubscribe_contributor_callback.call(contributor)
        end
      end

      subject do
        adapter.consume(signal_message)
        resubscribe_contributor_callback
      end

      context 'any text other than the keyword Bestellen' do
        it { is_expected.not_to have_received(:call) }
      end

      context 'with keyword Bestellen' do
        before { signal_message[:envelope][:dataMessage][:message] = 'Bestellen' }

        it { is_expected.to have_received(:call) }
      end
    end

    describe 'HANDLE_DELIVERY_RECEIPT' do
      let(:handle_delivery_receipt_callback) { spy('handle_delivery_receipt_callback') }
      let(:signal_message) { signal_receipt_message }

      before do
        adapter.on(SignalAdapter::HANDLE_DELIVERY_RECEIPT) do |delivery_receipt, contributor|
          handle_delivery_receipt_callback.call(delivery_receipt, contributor)
        end
      end

      subject do
        adapter.consume(signal_message)
        handle_delivery_receipt_callback
      end

      describe 'if the message is a delivery receipt' do
        it { should have_received(:call) }
      end
    end
  end
end
