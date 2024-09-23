# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WhatsAppAdapter::ThreeSixtyDialog::FileFetcherService, type: :model do
  describe '#call' do
    subject { -> { described_class.new(organization_id: organization.id, file_id: file_id).call } }

    let(:organization) { create(:organization) }
    let(:file_id) { 'some_valid_id' }

    let(:path) { '/whatsapp_business/attachments/' }
    let(:query) { "?mid=#{file_id}&ext=1727097743&hash=ATu6wfuxkGsA6z-jlTHimX3hb8TTrWgHeDsaLZ-Qs7ab6g" }
    let(:fetch_file_url) { "https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693/#{file_id}" }
    let(:fetch_streamable_file) do
      "https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693#{path}#{query}"
    end
    before do
      allow(ENV).to receive(:fetch).with('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT',
                                         'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693').and_return('https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
    end

    context 'successful' do
      before do
        stub_request(:get, fetch_file_url).to_return(status: 200,
                                                     body: { url: "https://someurl.com#{path}#{query}" }.to_json)
        stub_request(:get, fetch_streamable_file).to_return(status: 200, body: 'some_streamable_file')
      end

      it 'returns the streamable file' do
        expect(subject.call).to eq('some_streamable_file')
      end
    end

    context 'unsuccessfully fetches url' do
      before do
        allow(Sentry).to receive(:capture_exception)
        stub_request(:get, fetch_file_url).to_return(status: [404, 'Not Found'])
      end

      let(:expected_exception) do
        described_class::FetchError.new(
          "Fetching of #{file_id} failed with message: Not Found"
        )
      end

      it 'reports the error' do
        expect(Sentry).to receive(:capture_exception).with(expected_exception)

        subject.call
      end
    end

    context 'unsuccessfully fetches streamable file' do
      before do
        allow(Sentry).to receive(:capture_exception)
        stub_request(:get, fetch_file_url).to_return(status: 200,
                                                     body: { url: "https://someurl.com#{path}#{query}" }.to_json)
        stub_request(:get, fetch_streamable_file).to_return(status: [500, 'Internal Server Error'])
      end

      let(:expected_exception) do
        described_class::FetchError.new(
          "Fetching of #{file_id} failed with message: Internal Server Error"
        )
      end

      it 'reports the error' do
        expect(Sentry).to receive(:capture_exception).with(expected_exception)

        subject.call
      end
    end
  end
end
