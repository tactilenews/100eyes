# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialog::UploadFileJob do
  describe '#perform_later(message_id:)' do
    subject { -> { described_class.new.perform(message_id: message.id) } }

    let(:organization) { create(:organization, three_sixty_dialog_client_api_key: 'valid_api_key') }
    let(:message) { create(:message, request: create(:request, :with_file, organization: organization)) }
    let(:external_file_id) { '545466424653131' }

    it 'schedules a job to send out the message with the file', vcr: { cassette_name: :three_sixty_dialog_upload_file_job } do
      expect { subject.call }.to have_enqueued_job(
        WhatsAppAdapter::ThreeSixtyDialogOutbound::File
      ).with({
               message_id: message.id,
               file_id: external_file_id
             })
    end
  end
end
