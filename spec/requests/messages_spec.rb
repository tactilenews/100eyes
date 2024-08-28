# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/messages', type: :request do
  let(:organization) { create(:organization) }
  let(:contributor) { create(:contributor, organization: organization) }
  let(:request) { create(:request, organization: organization) }
  let(:user) { create(:user, organizations: [organization]) }
  let(:message) { create(:message, request: request) }

  describe 'GET /new' do
    it 'should be successful' do
      get new_organization_message_url(organization_id: request.organization_id, as: user,
                                       params: { request_id: request.id, contributor_id: contributor.id })
      expect(response).to be_successful
    end
  end

  describe 'POST /messages' do
    let(:msg_attrs) { { text: 'Triangles are my favorite shape.' } }
    subject do
      lambda {
        post organization_messages_url(organization, as: user),
             params: { message: msg_attrs, request_id: request.id, contributor_id: contributor.id }
      }
    end

    it { should change { Message.count }.from(0).to(1) }

    it 'redirects to the conversation link the message belongs to' do
      subject.call
      expect(response).to redirect_to(Message.first.chat_message_link)
    end

    it 'shows success notification' do
      subject.call
      expect(flash[:success]).not_to be_empty
    end

    it 'saves current user as creator' do
      should change { Message.pluck(:creator_id) }.from([]).to([user.id])
    end
  end

  describe 'PATCH /message/:id' do
    let(:previous_text) { 'Previous text' }
    let(:message) { create(:message, creator_id: user.id, text: previous_text, request: request) }
    let(:new_attrs) { { text: 'Grab your coat and get your hat' } }
    subject { -> { patch organization_message_url(message.organization, message, as: user), params: { message: new_attrs } } }

    it { should change { message.reload && message.text }.from(previous_text).to('Grab your coat and get your hat') }

    it 'shows success notification' do
      subject.call
      expect(flash[:success]).not_to be_empty
    end

    it 'redirects to the conversation link the message belongs to' do
      subject.call
      expect(response).to redirect_to(message.chat_message_link)
    end

    context 'not manually created message' do
      let(:message) { create(:message, creator_id: nil, request: request) }

      it 'does not update the requested message' do
        subject.call
        expect(response).not_to be_successful
      end

      it 'shows error notification' do
        subject.call
        expect(flash[:error]).not_to be_empty
      end
    end
  end
end
