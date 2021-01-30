# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailAdapter do
  let(:adapter) { EmailAdapter.new(message: message) }
  before { allow(Setting).to receive(:application_host).and_return('example.org') }

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
end
