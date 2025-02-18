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
              id: 'zuNhdpIHpRU_9Du-B4oH',
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
    allow(File).to receive(:open)
      .with('signal-cli-config/attachments/zuNhdpIHpRU_9Du-B4oH')
      .and_return(file_fixture('example-image.png').open)
  end

  let(:phone_number) { '+4912345789' }

  let!(:contributor) do
    create(
      :contributor,
      id: 4711,
      signal_phone_number: phone_number,
      signal_onboarding_completed_at: 1.day.ago,
      organization: organization
    )
  end
  let(:organization) { create(:organization) }

  describe '#consume' do
    let(:message) do
      adapter.consume(contributor, signal_message) do |message|
        return message
      end
    end

    describe '|message| block argument' do
      subject { message }

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

      context 'unsupported content' do
        let(:unsupported_content_message) do
          contributor.organization.signal_unknown_content_message
        end

        context 'if the message contains a contact' do
          before { signal_message[:envelope][:dataMessage][:contacts] = ['Käptn Blaubär'] }

          it 'schedules a job to inform the contributor it is not supported' do
            expect { subject }.to have_enqueued_job(SignalAdapter::Outbound::Text).with(
              contributor_id: contributor.id,
              text: unsupported_content_message
            )
          end

          it 'sets the unknown_content of the message' do
            expect(subject.unknown_content).to eq(true)
          end
        end

        context 'if the message contains a sticker' do
          before do
            signal_message[:envelope][:dataMessage][:sticker] = {
              packId: 'zMiaBdwHeFa1c1HpBpeXbA==',
              packKey: 'RXMOYPCdVWYRUiN0RTemt9nqmc7qy3eh+9aAG5YH+88=',
              stickerId: 3
            }
          end

          it 'schedules a job to inform the contributor it is not supported' do
            expect { subject }.to have_enqueued_job(SignalAdapter::Outbound::Text).with(
              contributor_id: contributor.id,
              text: unsupported_content_message
            )
          end

          it 'sets the unknown_content of the message' do
            expect(subject.unknown_content).to eq(true)
          end
        end

        context 'if the message contains a mention' do
          before { signal_message[:envelope][:dataMessage][:mentions] = ['everyone'] }

          it 'schedules a job to inform the contributor it is not supported' do
            expect { subject }.to have_enqueued_job(SignalAdapter::Outbound::Text).with(
              contributor_id: contributor.id,
              text: unsupported_content_message
            )
          end

          it 'sets the unknown_content of the message' do
            expect(subject.unknown_content).to eq(true)
          end
        end

        context 'if the message contains unsupported attachments' do
          let(:signal_message) { signal_message_with_attachment }
          before { signal_message[:envelope][:dataMessage][:attachments][0][:contentType] = ['application/pdf'] }

          it 'schedules a job to inform the contributor it is not supported' do
            expect { subject }.to have_enqueued_job(SignalAdapter::Outbound::Text).with(
              contributor_id: contributor.id,
              text: unsupported_content_message
            )
          end

          it 'sets the unknown_content of the message' do
            expect(subject.unknown_content).to eq(true)
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

    describe '|message|request' do
      context 'given no quote reply id present in message payload' do
        context 'given a received request' do
          let(:newer_request) { create(:request, tag_list: ['not for you']) }
          let(:outbound_message) { create(:message, :with_request, :outbound, recipient: contributor) }

          before do
            newer_request
            outbound_message
          end

          it 'is expected to attach their latest request' do
            expect(message.request).to eq(outbound_message.request)
          end
        end

        context 'given no received request, but a request in the db' do
          let(:request) { create(:request, tag_list: ['not for you'], organization: contributor.organization) }

          before do
            request
          end

          it 'is expected not to raise an error' do
            expect { subject }.not_to raise_error
          end

          it 'saves the reply' do
            expect(message).to be_persisted
          end

          it 'is expected to be nil' do
            expect(message.request).to be_nil
          end
        end

        context 'given no request in the db' do
          it 'is expected not to raise an error' do
            expect { subject }.not_to raise_error
          end

          it 'saves the reply' do
            expect(message).to be_persisted
          end
        end
      end
    end

    context 'given the keyword Abbestellen' do
      subject { message }
      before { signal_message[:envelope][:dataMessage][:message] = 'Abbestellen' }

      it 'does not create a message' do
        expect { subject }.not_to change(Message, :count)
      end

      it 'schedules a job to unsubscribe the contributor' do
        expect { subject }.to have_enqueued_job(UnsubscribeContributorJob).with(contributor.id, SignalAdapter::Outbound)
      end
    end

    context 'given the keyword Bestellen' do
      subject { message }
      before do
        contributor.update!(unsubscribed_at: 1.week.ago)
        signal_message[:envelope][:dataMessage][:message] = 'Bestellen'
      end

      it 'does not create a message' do
        expect { subject }.not_to change(Message, :count)
      end

      it 'schedules a job to resubscribe the contributor' do
        expect { subject }.to have_enqueued_job(ResubscribeContributorJob).with(contributor.id, SignalAdapter::Outbound)
      end
    end

    context 'given a quote reply' do
      let(:signal_message) do
        {
          envelope: {
            source: '+4912345789',
            sourceNumber: '+4912345789',
            sourceUuid: 'valid_uuid',
            sourceName: 'Signal Contributor',
            sourceDevice: 1,
            timestamp: 1_739_787_870_717,
            serverReceivedTimestamp: 1_739_787_903_865,
            serverDeliveredTimestamp: 1_739_787_913_966,
            dataMessage: {
              timestamp: 1_739_787_870_717,
              message: 'Got it!',
              expiresInSeconds: 0,
              viewOnce: false,
              quote: {
                id: 1_739_787_468_560,
                author: organization.signal_server_phone_number,
                authorNumber: organization.signal_server_phone_number,
                authorUuid: 'valid_uuid',
                text: 'This is a reply to your message',
                attachments: []
              }
            }
          },
          account: organization.signal_server_phone_number
        }
      end

      it 'saves the quote id to the reply_to_external_id' do
        expect(message.reply_to_external_id).to eq('1739787468560')
      end

      context 'given a message with the id can be found' do
        subject { message.request }
        let(:outbound_message) { create(:message, :with_request, :outbound, recipient: contributor, external_id: '1739787468560') }

        before do
          outbound_message
          create_list(:request, 2)
        end

        it 'attaches the request' do
          expect(subject).to eq(outbound_message.request)
        end
      end
    end
  end
end
