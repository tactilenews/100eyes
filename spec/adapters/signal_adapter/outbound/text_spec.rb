# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe SignalAdapter::Outbound::Text do
  let(:adapter) { described_class.new }
  let(:organization) { create(:organization, signal_server_phone_number: 'SIGNAL_SERVER_PHONE_NUMBER') }
  let(:contributor) { create(:contributor, signal_phone_number: '+4915112345678', email: nil, organization: organization) }
  let(:message) { create(:message, :with_file, text: 'Hello Signal') }
  let(:organization_id) { organization.id }
  let(:contributor_id) { contributor.id }
  let(:perform) { -> { adapter.perform(organization_id: organization_id, contributor_id: contributor_id, text: message.text) } }

  describe 'perform' do
    subject { perform }
    before do
      allow(ENV).to receive(:fetch).with(
        'SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080'
      ).and_return('http://signal:8080')
      allow(ENV).to receive(:fetch).with(
        'ATTR_ENCRYPTED_KEY', nil
      ).and_return("f6mqCaVvZQHJaNJtKLEFbPaXflxpGsF9xVeWgWJb3tw=\n")
      allow(Sentry).to receive(:capture_exception)
    end

    describe 'signal-rest-cli HTTP response status' do
      describe 'on success' do
        before { stub_request(:post, 'http://signal:8080/v2/send').to_return(status: 201) }
        it { should_not raise_error }
      end

      describe 'on error' do
        let(:error_message) { 'Unregistered user' }
        before(:each) { stub_request(:post, 'http://signal:8080/v2/send').to_return(status: 400, body: { error: error_message }.to_json) }

        it 'reports the error' do
          expect(Sentry).to receive(:capture_exception).with(SignalAdapter::BadRequestError.new(error_code: 400, message: error_message))

          subject.call
        end
      end
    end

    describe 'Unknown organization' do
      let(:organization_id) { 564_321 }

      it 'reports the error' do
        expect(Sentry).to receive(:capture_exception).with(ActiveRecord::RecordNotFound)

        subject.call
      end
    end

    describe 'Unknown contributor' do
      let(:contributor_id) { 564_321 }

      it 'reports the error' do
        expect(Sentry).to receive(:capture_exception).with(ActiveRecord::RecordNotFound)

        subject.call
      end

      context 'not part of organization' do
        let(:contributor_id) { create(:contributor).id }

        it 'reports the error' do
          expect(Sentry).to receive(:capture_exception).with(ActiveRecord::RecordNotFound)

          subject.call
        end
      end
    end

    describe 'sends HTTP requests', vcr: { cassette_name: :send_signal_message } do
      subject { perform.call and WebMock }

      it { should have_requested(:post, 'http://signal:8080/v2/send') }
      it { should have_requested(:post, 'http://signal:8080/v2/send').with(body: hash_including({ message: 'Hello Signal' })) }
      it { should have_requested(:post, 'http://signal:8080/v2/send').with(body: hash_including({ recipients: ['+4915112345678'] })) }
      it { should have_requested(:post, 'http://signal:8080/v2/send').with(body: hash_including({ number: 'SIGNAL_SERVER_PHONE_NUMBER' })) }
    end
  end
end
