# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe SignalAdapter::Outbound do
  let(:adapter) { described_class.new }
  let(:message) { create(:message, text: 'Forgot to ask: How are you?', broadcasted: true, recipient: contributor) }
  let(:contributor) { create(:contributor, email: nil) }

  describe '::send_welcome_message!' do
    subject { -> { described_class.send_welcome_message!(contributor) } }
    before { message } # we don't count the extra ::send here

    it { should_not enqueue_job }

    context 'contributor has a phone number' do
      let(:onboarding_completed_at) { nil }
      let(:contributor) do
        create(
          :contributor,
          signal_phone_number: '+491511234567',
          signal_onboarding_completed_at: onboarding_completed_at,
          email: nil
        )
      end

      it { should_not enqueue_job }

      context 'and has completed onboarding' do
        let(:onboarding_completed_at) { Time.zone.now }
        it { should enqueue_job(described_class) }
      end
    end
  end

  describe '::send!' do
    subject { -> { described_class.send!(message) } }
    before { message } # we don't count the extra ::send here
    it { should_not enqueue_job }

    describe 'contributor has a phone number' do
      let(:onboarding_completed_at) { nil }

      let(:contributor) do
        create(
          :contributor,
          email: nil,
          signal_phone_number: '+491511234567',
          signal_onboarding_completed_at: onboarding_completed_at
        )
      end

      it { should_not enqueue_job(described_class) }

      context 'and has completed onboarding' do
        let(:onboarding_completed_at) { Time.zone.now }
        it { should enqueue_job(described_class) }
      end
    end
  end

  describe 'perform' do
    let(:adapter) { described_class.new }
    let(:contributor) { create(:contributor, signal_phone_number: '+4915112345678', email: nil) }
    let(:perform) { -> { adapter.perform(message: build(:message, text: 'Hello Signal'), recipient: contributor) } }
    subject { perform }
    before do
      allow(Setting).to receive(:signal_server_phone_number).and_return('SIGNAL_SERVER_PHONE_NUMBER')
      allow(Setting).to receive(:signal_cli_rest_api_endpoint).and_return('http://signal:8080')
      allow(Sentry).to receive(:capture_exception)
    end

    describe 'signal-rest-cli HTTP response status' do
      describe 'on success' do
        before { stub_request(:post, 'http://signal:8080/v2/send').to_return(status: 201) }
        it { should_not raise_error }
      end

      describe 'on error' do
        before(:each) { stub_request(:post, 'http://signal:8080/v2/send').to_return(status: 400) }

        it 'reports the error' do
          expect(Sentry).to receive(:capture_exception).with(Net::HTTPClientException)

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
