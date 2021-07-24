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
      let(:contributor) { create(:contributor, phone_number: '+4915112345', email: nil) }
      it { should enqueue_job(described_class) }
    end
  end

  describe '::send!' do
    subject { -> { described_class.send!(message) } }
    before { message } # we don't count the extra ::send here
    it { should_not enqueue_job }

    describe 'contributor has a phone number' do
      let(:contributor) { create(:contributor, email: nil, phone_number: '+4915112345') }

      it { should enqueue_job(described_class) }
    end
  end

  describe 'perform', vcr: { cassette_name: :send_signal_message } do
    let(:adapter) { described_class.new }
    let(:contributor) { create(:contributor, phone_number: '+4915112345', email: nil) }
    let(:perform) { -> { adapter.perform(text: 'Hello Signal', recipient: contributor) } }
    subject { perform }
    before do
      allow(Setting).to receive(:signal_rest_cli_endpoint).and_return('http://signal:8080')
      allow(Setting).to receive(:signal_phone_number).and_return('+4915199999')
    end

    it { should_not raise_error }

    describe 'sends HTTP requests' do
      subject { perform.call and WebMock }

      it { should have_requested(:post, 'http://signal:8080/v2/send') }
      it { should have_requested(:post, 'http://signal:8080/v2/send').with(body: hash_including({ message: 'Hello Signal' })) }
      it { should have_requested(:post, 'http://signal:8080/v2/send').with(body: hash_including({ recipients: ['+4915112345'] })) }
      it { should have_requested(:post, 'http://signal:8080/v2/send').with(body: hash_including({ number: '+4915199999' })) }
    end
  end
end
