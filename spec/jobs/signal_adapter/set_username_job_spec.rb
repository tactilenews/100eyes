# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe SignalAdapter::SetUsernameJob do
  describe '#perform_later(organization_id:)' do
    subject { -> { described_class.new.perform(organization_id: organization.id) } }

    let(:organization) { create(:organization, signal_server_phone_number: '+4912345678') }

    before do
      allow(ENV).to receive(:fetch).with(
        'SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080'
      ).and_return('http://signal:8080')
    end

    it 'updates the signal_complete_onboarding_link', vcr: { cassette_name: :signal_set_username } do
      expect { subject.call }.to (change { organization.reload.signal_complete_onboarding_link }).from(nil).to('https://signal.me/some_valid_uuid')
    end
  end
end
