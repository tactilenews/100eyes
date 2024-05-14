# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Errors' do
  let(:user) { create(:user) }

  describe '404 not found' do
    subject { -> { get '/some-non-existent-endpoint' } }

    before { get dashboard_path(as: user) } # simulate sign in

    it 'should return status code' do
      subject.call
      expect(response).to have_http_status(:not_found)
    end
  end

  describe '500 internal server error' do
    subject { -> { patch message_url(message, as: user) } }

    let(:message) { create(:message, creator_id: user.id) }
    before { allow_any_instance_of(MessagesController).to receive(:update).and_raise(StandardError) }

    it 'should return status code' do
      subject.call
      expect(response).to have_http_status(:internal_server_error)
    end
  end
end
