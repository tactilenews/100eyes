# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Messages', type: :request do
  describe 'PATCH /messages/:id/highlight' do
    let(:params) { {} }
    let(:user) { create(:user) }

    subject do
      lambda do
        patch(message_highlight_url(message, format: :json, as: user), params: params)
      end
    end

    describe 'given an non-highlighted message' do
      let(:message) { create(:message, highlighted: false) }

      describe 'given highlighted=true' do
        let(:params) { { highlighted: true } }
        it { should change { message.reload.highlighted? }.from(false).to(true) }
      end

      describe 'given highlighted=false' do
        let(:params) { { highlighted: false } }
        it { should_not(change { message.reload.highlighted? }) }
      end
    end

    describe 'given a highlighted message' do
      let(:message) { create(:message, highlighted: true) }

      describe 'given highlighted=true' do
        let(:params) { { highlighted: true } }
        it { should_not(change { message.reload.highlighted? }) }
      end

      describe 'given highlighted=false' do
        let(:params) { { highlighted: false } }
        it { should change { message.reload.highlighted? }.from(true).to(false) }
      end
    end
  end

  describe 'POST /request' do
    let(:user) { create(:user) }
    let(:request) { create(:request) }

    subject { -> { patch(message_request_url(message, as: user), params: params) } }

    let(:message) { create(:message, request: request) }
    let(:other_request) { create(:request) }
    let(:params) { { message: { request_id: request_id } } }

    describe 'given an invalid request_id' do
      let(:request_id) { 'NOT AN ID' }

      it { should_not(change { message.request.id }) }

      it 'shows error message' do
        subject.call

        expect(flash[:error]).not_to be_empty
      end
    end

    describe 'given a valid request_id' do
      let(:request_id) { other_request.id }

      it 'updates request id' do
        subject.call

        expect(message.reload.request.id).to eq(other_request.id)
      end

      it 'redirects back to previous request' do
        subject.call

        anchor = "contributor-#{message.contributor.id}"
        url = request_url(request, anchor: anchor)

        expect(flash[:success]).not_to be_empty
        expect(response).to redirect_to url
      end
    end
  end
end
