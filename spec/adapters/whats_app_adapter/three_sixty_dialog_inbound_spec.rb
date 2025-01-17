# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialogInbound do
  let(:adapter) { described_class.new }
  let(:phone_number) { '+491511234567' }
  let(:whats_app_message) do
    { contacts: [{ profile: { name: 'Matthew Rider' },
                   wa_id: '491511234567' }],
      messages: [{ from: '491511234567',
                   id: 'wamid.valid_uuid',
                   text: { body: 'Hey' },
                   timestamp: '1692118778',
                   type: 'text' }] }
  end
  let(:whats_app_message_with_attachment) do
    { contacts: [{ profile: { name: 'Matthew Rider' },
                   wa_id: '491511234567' }],
      messages: [{ from: '491511234567',
                   id: 'some_valid_id',
                   image: {
                     caption: 'Look how cute',
                     id: 'some_valid_id',
                     mime_type: 'image/jpeg',
                     sha256: 'sha256_hash'
                   },
                   timestamp: '1692118778',
                   type: 'image' }] }
  end

  let(:organization) { create(:organization, contact_person: create(:user)) }
  let!(:contributor) { create(:contributor, whats_app_phone_number: phone_number, organization: organization) }
  let(:fetch_file_url) { 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693/some_valid_id' }
  let(:fetch_streamable_file) { 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693/somepath' }
  let(:request) { create(:request) }

  before do
    allow(ENV).to receive(:fetch).with('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT',
                                       'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693').and_return('https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
  end
  subject { -> { adapter.consume(organization, whats_app_message) } }

  describe '#consume' do
    let(:reply) do
      subject.call do |message|
        message
      end
    end

    describe '|message| block argument' do
      before do
        request
        allow(Sentry).to receive(:capture_exception)
      end

      it 'is expected to create a Message' do
        expect { subject.call }.to change(Message, :count).from(0).to(1)
      end

      it 'saves the external id to the message record' do
        expect(reply.external_id).to eq('wamid.valid_uuid')
      end

      context 'from an unknown contributor' do
        let!(:phone_number) { '+495555555' }

        it 'is expected not to create a Message' do
          expect { subject.call }.not_to change(Message, :count)
        end

        it 'reports an error to inform us there is a potential issue' do
          subject.call

          expect(Sentry).to have_received(:capture_exception).with(
            WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: '+491511234567')
          )
        end
      end

      context 'given a message with text and an attachment' do
        let(:whats_app_message) { whats_app_message_with_attachment }

        before do
          stub_request(:get, fetch_file_url).to_return(status: 200, body: { url: 'https://someurl.com/somepath' }.to_json)
          stub_request(:get, fetch_streamable_file).to_return(status: 200, body: 'some_streamable_file')
        end

        it 'is expected to store message text and attached file' do
          expect(reply.text).to eq('Look how cute')
          expect(reply.files.first.attachment).to be_attached
        end
      end
    end

    describe '|message|text' do
      before { request }

      context 'given a whats_app_message with a `message`' do
        it 'is expected to save the text' do
          expect(reply.text).to eq('Hey')
        end
      end

      context 'given a whats_app_message without a `message` and with an attachment' do
        let(:whats_app_message) { whats_app_message_with_attachment }
        before do
          whats_app_message[:messages].first[:image][:caption] = nil
          stub_request(:get, fetch_file_url).to_return(status: 200, body: { url: 'https://someurl.com/somepath' }.to_json)
          stub_request(:get, fetch_streamable_file).to_return(status: 200, body: 'some_streamable_file')
        end

        it 'is expected to be nil' do
          expect(reply.text).to be(nil)
        end
      end
    end

    describe '|message|raw_data' do
      before { request }

      it 'is expected to be attached' do
        expect(reply.raw_data).to be_attached
      end
    end

    describe '#sender' do
      before { request }

      it 'is expected to equal the contributor' do
        expect(reply.sender).to eq(contributor)
      end
    end

    describe '#request' do
      context 'given no quote reply id present in message payload' do
        context 'given a received request' do
          let(:newer_request) { create(:request, tag_list: ['not for you']) }
          let(:outbound_message) { create(:message, :outbound, request: request, recipient: contributor) }

          before do
            request
            outbound_message
          end

          it 'is expected to attach their latest request' do
            expect(reply.request).to eq(request)
          end
        end

        context 'given no received request, but a request in the db' do
          let(:request) { create(:request, tag_list: ['not for you']) }

          before do
            request
          end

          it 'is expected to attach the latest request' do
            expect(reply.request).to eq(request)
          end
        end

        context 'given no request in the db' do
          it 'is expected to raise an error' do
            expect { subject.call }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end

      describe 'given a quote reply' do
        context 'with an associated message record' do
          let(:outbound_message) do
            create(:message, :outbound, recipient: contributor, external_id: 'external_id')
          end
          before do
            outbound_message
            whats_app_message[:messages].first[:context] = { id: 'external_id' }
          end

          it "is expected to be the message's request" do
            expect(reply.request).to eq(outbound_message.request)
          end
        end
      end
    end

    describe '|message|files' do
      let(:whats_app_message) { whats_app_message_with_attachment }

      before do
        stub_request(:get, fetch_file_url).to_return(status: 200, body: { url: 'https://someurl.com/somepath' }.to_json)
        stub_request(:get, fetch_streamable_file).to_return(status: 200, body: 'some_streamable_file')
      end

      describe 'handling different content types' do
        let(:file) { reply.files.first }

        before { request }

        context 'given an audio file' do
          before do
            first_message = whats_app_message[:messages].first
            first_message[:type] = 'voice'
            first_message.delete(:image)
            first_message[:audio] = {
              id: 'some_valid_id',
              mime_type: 'audio/ogg',
              sha256: 'sha256_hash'
            }
          end

          it 'attaches the audio file' do
            expect(file.attachment).to be_attached
          end

          it 'preserves the content_type' do
            expect(file.attachment.blob.content_type).to eq('audio/ogg')
          end
        end

        context 'given an audio/mpeg file' do
          before do
            first_message = whats_app_message[:messages].first
            first_message[:type] = 'audio'
            first_message.delete(:image)
            first_message[:audio] = {
              id: 'some_valid_id',
              mime_type: 'audio/mpeg',
              sha256: 'sha256_hash'
            }
          end

          it 'attaches the audio file' do
            expect(file.attachment).to be_attached
          end

          it 'preserves the content_type' do
            expect(file.attachment.blob.content_type).to eq('audio/mpeg')
          end
        end

        context 'given an image file' do
          it 'attaches the image file' do
            expect(file.attachment).to be_attached
          end

          it 'preserves the content_type' do
            expect(file.attachment.blob.content_type).to eq('image/jpeg')
          end
        end

        context 'given attachment without filename' do
          it 'attaches the audio file' do
            expect(file.attachment).to be_attached
          end

          it 'sets a fallback filename based on external file id' do
            expect(file.attachment.filename.to_s).to eq('some_valid_id')
          end
        end

        context 'given a supported document' do
          before do
            first_message = whats_app_message[:messages].first
            first_message[:type] = 'document'
            first_message.delete(:image)
            first_message[:document] = {
              filename: 'AUD-12345.mpeg',
              id: 'some_valid_id',
              mime_type: 'audio/mpeg',
              sha256: 'sha256_hash'
            }
          end

          context 'with a filename' do
            it 'attaches the supported document file' do
              expect(file.attachment).to be_attached
            end

            it 'favors the filename' do
              expect(file.attachment.filename.to_s).to eq('AUD-12345.mpeg')
            end
          end
        end

        context 'voice' do
          let(:voice) do
            {
              id: 'some_valid_id',
              mime_type: 'audio/ogg; codecs=opus',
              sha256: 'sha256_hash'
            }
          end
          before do
            first_message = whats_app_message[:messages].first
            first_message[:type] = 'voice'
            first_message[:voice] = voice
          end

          it 'attaches the voice file' do
            expect(file.attachment).to be_attached
          end
        end

        context 'video' do
          let(:video) do
            {
              id: 'some_valid_id',
              mime_type: 'video/mp4',
              sha256: 'sha256_hash'
            }
          end
          before do
            first_message = whats_app_message[:messages].first
            first_message[:type] = 'video'
            first_message[:voice] = video
          end

          it 'attaches the video file' do
            expect(file.attachment).to be_attached
          end
        end

        context 'given an unsupported document' do
          before do
            first_message = whats_app_message[:messages].first
            first_message[:type] = 'document'
            first_message.delete(:image)
            first_message[:document] = {
              filename: 'Comprovante.pdf',
              id: 'some_valid_id',
              mime_type: 'application/pdf',
              sha256: 'sha256_hash'
            }
          end

          it 'does not attach the file' do
            expect(reply.files).to be_empty
          end
        end
      end
    end
  end

  describe 'given unsupported content' do
    let(:message) { whats_app_message[:messages].first }
    let(:unsupported_content_text) do
      I18n.t('adapter.whats_app.unsupported_content_template', first_name: contributor.first_name,
                                                               contact_person: contributor.organization.contact_person.name)
    end

    before do
      request
      message.delete(:text)
    end

    context 'document|pdf|' do
      let(:document) do
        {
          filename: 'Comprovante.pdf',
          id: 'some_valid_id',
          mime_type: 'application/pdf',
          sha256: 'sha256_hash'
        }
      end
      before do
        message[:type] = 'document'
        message[:document] = document
      end

      it 'it is expected to send a message to the contributor to inform them we do not accept the content' do
        expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
          contributor_id: contributor.id,
          type: :text,
          text: unsupported_content_text
        )
      end
    end

    context 'document|docx|' do
      let(:document) do
        {
          filename: 'price-list.docx',
          id: 'some_valid_id',
          mime_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          sha256: 'sha256_hash'
        }
      end
      before do
        message[:type] = 'document'
        message[:document] = document
      end

      it 'it is expected to send a message to the contributor to inform them we do not accept the content' do
        expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
          contributor_id: contributor.id,
          type: :text,
          text: unsupported_content_text
        )
      end
    end

    context 'location' do
      let(:location) do
        {
          latitude: '22.9871',
          longitude: '43.2048'
        }
      end
      before do
        message[:type] = 'location'
        message[:location] = location
      end

      it 'it is expected to send a message to the contributor to inform them we do not accept the content' do
        expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
          contributor_id: contributor.id,
          type: :text,
          text: unsupported_content_text
        )
      end
    end

    context 'contacts' do
      let(:contacts) do
        {
          contacts: [
            { addresses: [],
              emails: [],
              ims: [],
              name: {
                first_name: '360dialog',
                formatted_name: '360dialog Sandbox',
                last_name: 'Sandbox'
              },
              org: {},
              phones: [
                { phone: '+49 30 609859535',
                  type: 'Mobile',
                  wa_id: '4930609859535' }
              ], urls: [] }
          ],
          from: '4915143416265',
          id: 'some_valid_id',
          timestamp: '1692123428',
          type: 'contacts'
        }
      end
      before do
        message[:type] = 'contacts'
        message[:contacts] = contacts
      end

      it 'it is expected to send a message to the contributor to inform them we do not accept the content' do
        expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
          contributor_id: contributor.id,
          type: :text,
          text: unsupported_content_text
        )
      end
    end

    context 'sticker' do
      let(:sticker) do
        {
          mime_type: 'image/webp',
          sha256: 'sha256_hash',
          id: 'some_valid_id',
          animated: false
        }
      end

      before do
        message[:type] = 'sticker'
        message[:sticker] = sticker
      end

      it 'it is expected to send a message to the contributor to inform them we do not accept the content' do
        expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
          contributor_id: contributor.id,
          type: :text,
          text: unsupported_content_text
        )
      end
    end
  end

  describe 'given a request to receive the message' do
    let(:previous_message) { create(:message, :outbound, recipient: contributor) }
    let(:latest_message) { create(:message, :outbound, recipient: contributor) }

    before do
      previous_message
      latest_message
      whats_app_message[:messages].first[:context] = { id: 'some_external_id' }
    end

    describe 'with no WhatsApp template sent' do
      it 'does not schedule a job' do
        expect { subject.call }.not_to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text)
      end

      describe 'but sending the answer request keyword' do
        before do
          organization.whats_app_quick_reply_button_text['answer_request'] = 'Antworten'
          organization.save

          whats_app_message[:messages].first[:text][:body] = 'Antworten'
        end

        it 'updates the timestamp to mark they sent us a message' do
          expect { subject.call }.to change {
            contributor.reload.whats_app_message_template_responded_at
          }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
        end

        it "sends out the contributor's latest message" do
          expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
            contributor_id: contributor.id,
            type: :text,
            message_id: latest_message.id
          )
        end
      end
    end

    describe 'with a WhatsApp template sent' do
      let(:whats_app_template) { create(:message_whats_app_template, message: previous_message, external_id: 'some_external_id') }

      before { whats_app_template }

      it 'updates the timestamp to mark they sent us a message' do
        expect { subject.call }.to change {
          contributor.reload.whats_app_message_template_responded_at
        }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))
      end

      it "sends out the contributor's latest message" do
        expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
          contributor_id: contributor.id,
          type: :text,
          message_id: previous_message.id
        )
      end
    end
  end

  describe 'given a request to unsubscribe' do
    before do
      whats_app_message[:messages].first[:text] = { body: 'Abbestellen' }
    end

    it 'schedules a job to unsubscribe the contributor' do
      expect { subject.call }.to have_enqueued_job(UnsubscribeContributorJob).with(
        contributor.organization.id,
        contributor.id,
        WhatsAppAdapter::ThreeSixtyDialogOutbound
      )
    end
  end

  describe 'given a request to resubscribe' do
    before do
      whats_app_message[:messages].first[:text] = { body: 'Bestellen' }
    end

    it 'schedules a job to resubscribe the contributor' do
      expect { subject.call }.to have_enqueued_job(ResubscribeContributorJob).with(
        contributor.organization.id,
        contributor.id,
        WhatsAppAdapter::ThreeSixtyDialogOutbound
      )
    end
  end
end
