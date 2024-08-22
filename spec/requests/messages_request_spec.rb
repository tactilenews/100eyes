# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Messages', type: :request do
  let(:organization) { create(:organization) }
  let(:request) { create(:request, organization: organization) }

  describe 'PATCH /messages/:id/highlight' do
    let(:params) { {} }
    let(:user) { create(:user, organizations: [organization]) }

    subject do
      lambda do
        patch(organization_message_highlight_url(message, organization_id: message.organization_id, format: :json, as: user),
              params: params)
      end
    end

    describe 'given an non-highlighted message' do
      let(:message) { create(:message, highlighted: false, request: request) }

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
      let(:message) { create(:message, highlighted: true, request: request) }

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

  describe 'GET /request' do
    let(:user) { create(:user, organizations: [message.organization]) }
    let(:contributor) { create(:contributor, first_name: 'Zora', last_name: 'Zimmermann', organization: organization) }

    before(:each) { get(organization_message_request_url(message.organization, message, as: user)) }

    context 'given an inbound message' do
      let(:message) { create(:message, sender: contributor, recipient: nil, request: request) }

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
    let(:user) { create(:user, organizations: [organization]) }

    subject { -> { patch(organization_message_request_url(message.organization, message, as: user), params: params) } }

    let(:message) { create(:message, request: request) }
    let(:other_request) { create(:request) }
    let(:params) { { message: { request_id: request_id } } }

    describe 'given an invalid request_id' do
      let(:request_id) { 'NOT AN ID' }

      it { should_not(change { message.request.id }) }

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
        url = organization_request_url(request.organization_id, request, anchor: anchor)

        expect(flash[:success]).not_to be_empty
        expect(response).to redirect_to url
      end
    end
  end
end
