# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PostmarkAdapter::Outbound do
  let(:adapter) { described_class.new(message: message) }
  let(:request) { create(:request) }
  before { allow(Setting).to receive(:application_host).and_return('example.org') }

  describe '#message_stream' do
    subject { adapter.message_stream }
    let(:message) { create(:message, broadcasted: false, request: request) }

    it { should eq(Setting.postmark_transactional_stream) }

    context 'given message is broadcasted as part of a request' do
      let(:broadcasted) { true }
      let(:message) { create(:message, broadcasted: true, request: request) }
      it { should eq(Setting.postmark_broadcasts_stream) }
    end
  end

  describe '#subject' do
    subject { adapter.subject }

    context 'given message is broadcasted as part of a request' do
      let(:message) { create(:message, broadcasted: true) }
      it { should eq('Die Redaktion hat eine neue Frage') }
    end

    context 'given message is a follow up chat message' do
      let(:message) { create(:message, broadcasted: false) }
      it { should eq('Re: Die Redaktion hat eine neue Frage') }
    end
  end

  describe 'email headers' do
    subject { adapter.headers }
    context 'given a request with id 4711' do
      let(:request) { create(:request, id: 4711) }

      context 'given message is broadcasted as part of a request' do
        let(:message) { create(:message, broadcasted: true, request: request) }
        it { is_expected.to include('message-id': 'request/4711@example.org') }
        it { is_expected.not_to include(:references) }
      end

      context 'given message is a follow up chat message' do
        let(:message) { create(:message, id: 42, request: request) }
        it { is_expected.to include('message-id': 'request/4711/message/42@example.org') }
        it { is_expected.to include(references: 'request/4711@example.org') }
      end
    end
  end

  describe '#send!' do
    subject { adapter.send! }
    let(:message) { build(:message, text: 'How do you do?', broadcasted: true, recipient: contributor) }
    let(:contributor) { create(:contributor, email: 'contributor@example.org') }

    it 'enqueues a Mailer' do
      expect { subject }.to have_enqueued_job.on_queue('mailers').with(
        'Mailer',
        'email',
        'deliver_now', # How ActionMailer works in test environment, even though in production we call deliver_later
        {
          params: {
            mail: { to: 'contributor@example.org', subject: 'Die Redaktion hat eine neue Frage', message_stream: 'broadcasts' },
            text: 'How do you do?',
            headers: { "message-id": anything }
          },
          args: []
        }
      )
    end
  end
end
