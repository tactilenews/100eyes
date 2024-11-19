# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialogOutbound::File do
  subject { -> { described_class.new.perform(message_id: message.id) } }

  describe '#perform_later(message_id:)' do
    let(:organization) { create(:organization, three_sixty_dialog_client_api_key: 'valid_client_api_key') }
    let(:message) do
      create(:message, request: create(:request, whats_app_external_file_ids: ['883247393974022']), organization: organization,
                       recipient: create(:contributor, whats_app_phone_number: '+4915123456789', email: nil))
    end
    let(:text_payload) do
      {
        messaging_product: 'whatsapp',
        recipient_type: 'individual',
        to: message.recipient.whats_app_phone_number.split('+').last,
        type: 'text',
        text: {
          body: message.text
        }
      }
    end

    before do
      allow(ENV).to receive(:fetch).with('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT',
                                         'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693').and_return('https://waba-v2.360dialog.io')
      allow(ENV).to receive(:fetch).with('ATTR_ENCRYPTED_KEY',
                                         nil).and_return(Base64.encode64(OpenSSL::Cipher.new('aes-256-gcm').random_key))
    end

    it "updates the message's external_id", vcr: { cassette_name: 'three_sixty_dialog_send_file' } do
      expect { subject.call }.to (change do
                                    message.reload.external_id
                                  end).from(nil).to('wamid.HBgNNDkxNTE0MzQxNjI2NRUCABEYEjJGRDRDQzJDOUYxMjVEQzExRQA=')
    end

    context 'with one file and text longer than 1023', vcr: { cassette_name: 'three_sixty_dialog_send_file_long_text' } do
      before { message.update!(text: Faker::Lorem.characters(number: 1024)) }

      it 'schedules a text message to be sent separately' do
        expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
          organization_id: organization.id,
          payload: text_payload,
          message_id: message.id
        )
      end
    end

    context 'with multiple files' do
      before do
        message.request.whats_app_external_file_ids << '371901912601458'
        message.request.save!
      end

      it 'schedules a text message to be sent separately', vcr: { cassette_name: 'three_sixty_dialog_send_files' } do
        expect { subject.call }.to have_enqueued_job(WhatsAppAdapter::ThreeSixtyDialogOutbound::Text).with(
          organization_id: organization.id,
          payload: text_payload,
          message_id: message.id
        )
      end
    end
  end
end
