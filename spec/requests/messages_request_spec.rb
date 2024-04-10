# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Messages', type: :request do
  describe 'PATCH /messages/:id/highlight' do
    subject do
      lambda do
        patch(message_highlight_url(message, format: :json, as: user), params: params)
      end
    end

    let(:params) { {} }
    let(:user) { create(:user) }

    describe 'given an non-highlighted message' do
      let(:message) { create(:message, highlighted: false) }

      describe 'given highlighted=true' do
        let(:params) { { highlighted: true } }

        it { is_expected.to change { message.reload.highlighted? }.from(false).to(true) }
      end

      describe 'given highlighted=false' do
        let(:params) { { highlighted: false } }

        it { is_expected.not_to(change { message.reload.highlighted? }) }
      end
    end

    describe 'given a highlighted message' do
      let(:message) { create(:message, highlighted: true) }

      describe 'given highlighted=true' do
        let(:params) { { highlighted: true } }

        it { is_expected.not_to(change { message.reload.highlighted? }) }
      end

      describe 'given highlighted=false' do
        let(:params) { { highlighted: false } }

        it { is_expected.to change { message.reload.highlighted? }.from(true).to(false) }
      end
    end
  end

  describe 'GET /request' do
    let(:user) { create(:user) }
    let(:contributor) { create(:contributor, first_name: 'Zora', last_name: 'Zimmermann') }

    before { get(message_request_url(message, as: user)) }

    context 'given an inbound message' do
      let(:message) { create(:message, sender: contributor, recipient: nil) }

      it 'renders successfully' do
        expect(response).to be_successful
        expect(response.body).to include('Zora Zimmermann')
      end
    end

    context 'given an outbound message' do
      let(:message) { create(:message, sender: nil, recipient: contributor, broadcasted: true) }

      it 'renders successfully' do
        expect(response).to be_successful
        expect(response.body).to include('Zora Zimmermann')
      end
    end
  end

  describe 'POST /request' do
    subject { -> { patch(message_request_url(message, as: user), params: params) } }

    let(:user) { create(:user) }
    let(:message) { create(:message, request: request) }
    let(:other_request) { create(:request) }
    let(:params) { { message: { request_id: request_id } } }
    let(:request) { create(:request) }

    describe 'given an invalid request_id' do
      let(:request_id) { 'NOT AN ID' }

      it { is_expected.not_to(change { message.request.id }) }

      it 'shows error message' do
        subject.call

        expect(flash[:error]).to eq(I18n.t('message.move.error'))
      end
    end

    describe 'given a valid request_id' do
      let(:request_id) { other_request.id }

      it 'updates request id' do
        expect { subject.call }.to (change { message.reload.request.id }).from(request.id).to(other_request.id)
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
