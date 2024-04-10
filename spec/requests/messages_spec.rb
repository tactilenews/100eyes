# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/messages', type: :request do
  let(:contributor) { create(:contributor) }
  let(:request) { create(:request) }
  let(:user) { create(:user) }
  let(:message) { create(:message) }

  describe 'GET /new' do
    it 'is successful' do
      get new_message_url(as: user, params: { request_id: request, contributor_id: contributor })
      expect(response).to be_successful
    end
  end

  describe 'POST /messages' do
    subject { -> { post messages_url(as: user), params: { message: msg_attrs, request_id: request.id, contributor_id: contributor.id } } }

    let(:msg_attrs) { { text: 'Triangles are my favorite shape.' } }

    it { is_expected.to change(Message, :count).from(0).to(1) }

    it 'redirects to the conversation link the message belongs to' do
      subject.call
      expect(response).to redirect_to(contributor_request_path(id: request.id, contributor_id: contributor.id))
    end

    it 'shows success notification' do
      subject.call
      expect(flash[:success]).not_to be_empty
    end

    it 'saves current user as creator' do
      expect(subject).to change { Message.pluck(:creator_id) }.from([]).to([user.id])
    end
  end

  describe 'PATCH /message/:id' do
    subject { -> { patch message_url(message, as: user), params: { message: new_attrs } } }

    let(:previous_text) { 'Previous text' }
    let(:message) { create(:message, creator_id: user.id, text: previous_text) }
    let(:new_attrs) { { text: 'Grab your coat and get your hat' } }

    it { is_expected.to change { message.reload && message.text }.from(previous_text).to('Grab your coat and get your hat') }

    it 'shows success notification' do
      subject.call
      expect(flash[:success]).not_to be_empty
    end

    it 'redirects to the conversation link the message belongs to' do
      subject.call
      expect(response).to redirect_to(contributor_request_path(id: message.request_id, contributor_id: message.sender_id))
    end

    context 'not manually created message' do
      let(:message) { create(:message, creator_id: nil) }

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
