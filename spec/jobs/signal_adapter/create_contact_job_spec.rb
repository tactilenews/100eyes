# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe SignalAdapter::CreateContactJob, type: :job do
  describe '#perform(contributor)' do
    subject { -> { described_class.new.perform(contributor) } }
    let(:contributor) { create(:contributor, signal_phone_number: '+491212343434', first_name: 'Robin', last_name: 'Hood') }

    before do
      allow(Setting).to receive(:signal_server_phone_number).and_return('SIGNAL_SERVER_PHONE_NUMBER')
      allow(Setting).to receive(:signal_cli_rest_api_endpoint).and_return('http://signal:8080')
      stub_request(:put, "http://signal:8080/v1/contacts/#{Setting.signal_server_phone_number}")
    end

    it 'sends a contact creation request to the signal api endpoint' do
      subject.call
      expect(a_request(:put, "#{Setting.signal_cli_rest_api_endpoint}/v1/contacts/#{Setting.signal_server_phone_number}")
        .with(body: {
                recipient: '+491212343434',
                name: 'Robin Hood'
              },
              headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })).to have_been_made
    end
  end
end
