# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialog::UploadFileService do
  describe '#call(request_id:)' do
    subject { -> { described_class.call(request_id: message.request.id) } }

    let(:organization) { create(:organization, three_sixty_dialog_client_api_key: 'valid_api_key') }
    let(:message) { create(:message, request: create(:request, :with_file, organization: organization)) }
    let(:external_file_id) { '545466424653131' }

    before do
      allow(ENV).to receive(:fetch).with(
        'THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693'
      ).and_return('https://waba-v2.360dialog.io')
    end

    it "updates the request's external_file_ids", vcr: { cassette_name: :three_sixty_dialog_upload_file_service } do
      expect { subject.call }.to (change { message.reload.request.external_file_ids }).from([]).to([external_file_id])
    end
  end
end
