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
                   id: 'some_valid_id',
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

  before do
    allow(ENV).to receive(:fetch).with('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT',
                                       'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693').and_return('https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
  end

  describe '#consume' do
    let(:message) do
      adapter.consume(organization, whats_app_message) do |message|
        message
      end
    end

    describe '|message| block argument' do
      subject { message }
      it { is_expected.to be_a(Message) }

      context 'from an unknown contributor' do
        let!(:phone_number) { '+495555555' }

        it { is_expected.to be(nil) }
      end

      context 'given a message with text and an attachment' do
        let(:whats_app_message) { whats_app_message_with_attachment }

        before do
          stub_request(:get, fetch_file_url).to_return(status: 200, body: { url: 'https://someurl.com/somepath' }.to_json)
          stub_request(:get, fetch_streamable_file).to_return(status: 200, body: 'some_streamable_file')
        end

        it 'is expected to store message text and attached file' do
          expect(message.text).to eq('Look how cute')
          expect(message.files.first.attachment).to be_attached
        end
      end
    end

    describe '|message|text' do
      subject { message.text }

      context 'given a whats_app_message with a `message`' do
        it { is_expected.to eq('Hey') }
      end

      context 'given a whats_app_message without a `message` and with an attachment' do
        let(:whats_app_message) { whats_app_message_with_attachment }
        before do
          whats_app_message[:messages].first[:image][:caption] = nil
          stub_request(:get, fetch_file_url).to_return(status: 200, body: { url: 'https://someurl.com/somepath' }.to_json)
          stub_request(:get, fetch_streamable_file).to_return(status: 200, body: 'some_streamable_file')
        end

        it { is_expected.to be(nil) }
      end
    end

    describe '|message|raw_data' do
      subject { message.raw_data }
      it { is_expected.to be_attached }
    end

    describe '#sender' do
      subject { message.sender }

      it { is_expected.to eq(contributor) }
    end

    describe '#request' do
      subject { message.request }

      context 'given no quote reply id present in message payload' do
        it 'is expected to be nil' do
          expect(subject).to be(nil)
        end
      end

      describe 'give a quote reply' do
        context 'with no message record' do
          before { whats_app_message[:messages].first[:context] = { id: 'you_cant_find_me' } }

          it 'is expected to be nil' do
            expect(subject).to be(nil)
          end
        end

        context 'with an associated message record' do
          let(:outbound_message) do
            create(:message, :outbound, recipient: contributor, external_id: 'external_id')
          end
          before do
            outbound_message
            whats_app_message[:messages].first[:context] = { id: 'external_id' }
          end

          it "is expected to be the message's request" do
            expect(subject).to eq(message.request)
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
        let(:file) { message.files.first }
        subject { file.attachment }

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

          it { is_expected.to be_attached }

          it 'preserves the content_type' do
            expect(subject.blob.content_type).to eq('audio/ogg')
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

          it { is_expected.to be_attached }

          it 'preserves the content_type' do
            expect(subject.blob.content_type).to eq('audio/mpeg')
          end
        end

        context 'given an image file' do
          it { is_expected.to be_attached }

          it 'preserves the content_type' do
            expect(subject.blob.content_type).to eq('image/jpeg')
          end
        end

        context 'given attachment without filename' do
          it { is_expected.to be_attached }

          it 'sets a fallback filename based on external file id' do
            expect(subject.filename.to_s).to eq('some_valid_id')
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
            it { is_expected.to be_attached }

            it 'favors the filename' do
              expect(subject.filename.to_s).to eq('AUD-12345.mpeg')
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

          it { is_expected.to be_attached }
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

          it { is_expected.to be_attached }
        end

        context 'given an unsupported document' do
          subject { message.files }

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

          it { is_expected.to be_empty }
        end
      end
    end
  end

  describe 'given an unknown sender' do
    subject do
      adapter.consume(organization, whats_app_message)
    end

    before do
      whats_app_message[:contacts].first[:wa_id] = '4955443322'
      allow(Sentry).to receive(:capture_exception)
    end

    it 'it is expected to throw an error to advise us there might be a problem' do
      subject

      exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: '+4955443322')
      expect(Sentry).to have_received(:capture_exception).with(exception)
    end
  end

  describe 'given unsupported content' do
    subject do
      adapter.consume(organization, whats_app_message)
    end

    let(:message) { whats_app_message[:messages].first }
    let(:unsupported_content_text) do
      I18n.t('adapter.whats_app.unsupported_content_template', first_name: contributor.first_name,
                                                               contact_person: contributor.organization.contact_person.name)
    end

    before do
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
        expect { subject }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
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
        expect { subject }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
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
        expect { subject }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
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
        expect { subject }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
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
        expect { subject }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
          contributor_id: contributor.id,
          type: :text,
          text: unsupported_content_text
        )
      end
    end
  end

  describe 'given a request to receive the message' do
    subject do
      adapter.consume(organization, whats_app_message)
    end

    before do
      create(:message)
      whats_app_message[:messages].first[:context] = { id: 'some_external_id' }
    end

    describe 'with no WhatsApp template sent' do
      it 'does not schedule a job' do
        expect { subject }.not_to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::HandleEphemeralDataJob)
      end

      describe 'but sending the answer request keyword' do
        before do
          organization.whats_app_quick_reply_button_text['answer_request'] = 'Antworten'
          organization.save

          whats_app_message[:messages].first[:text][:body] = 'Antworten'
        end

        it 'is expected to schedule a job  to handle the ephemeral data' do
          expect { subject }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::HandleEphemeralDataJob).with(
            type: :request_to_receive_message,
            contributor_id: contributor.id,
            message_id: nil
          )
        end
      end
    end

    describe 'with a WhatsApp template sent' do
      let(:whats_app_template) { create(:message_whats_app_template, message: create(:message), external_id: 'some_external_id') }

      it 'is expected to schedule a job to handle the ephemeral data' do
        expect { subject }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::HandleEphemeralDataJob).with(
          type: :request_to_receive_message,
          contributor_id: contributor.id,
          message_id: whats_app_template.message.id
        )
      end
    end
  end

  describe 'given a request to unsubscribe' do
    subject do
      adapter.consume(organization, whats_app_message)
    end

    before do
      whats_app_message[:messages].first[:text] = { body: 'Abbestellen' }
    end

    it 'is expected to schedule a job  to handle the ephemeral data' do
      expect { subject }.not_to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::HandleEphemeralDataJob).with(
        type: :unsubscribe,
        contributor_id: contributor.id
      )
    end
  end

  describe 'given a request to resubscribe' do
    subject do
      adapter.consume(organization, whats_app_message)
    end

    before do
      whats_app_message[:messages].first[:text] = { body: 'Bestellen' }
    end

    it 'is expected to schedule a job  to handle the ephemeral data' do
      expect { subject }.not_to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialog::HandleEphemeralDataJob).with(
        type: :resubscribe,
        contributor_id: contributor.id
      )
    end
  end
end
