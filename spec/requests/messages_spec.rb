# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/messages', type: :request do
  let(:contributor) { create(:contributor) }
  let(:request) { create(:request) }
  let(:user) { create(:user) }

  describe 'GET /new' do
    it 'should be successful' do
      get new_message_url(as: user, params: { request_id: request, contributor_id: contributor })
      expect(response).to be_successful
    end
  end

  describe 'POST /messages' do
    let(:msg_attrs) { { text: 'Triangles are my favorite shape.' } }
    subject { -> { post messages_url(as: user), params: { message: msg_attrs, request_id: request.id, contributor_id: contributor.id } } }

    it { should change { Message.count }.from(0).to(1) }

    it 'redirects to the conversation link the message belongs to' do
      subject.call
      expect(response).to redirect_to(contributor_request_path(id: request.id, contributor_id: contributor.id))
    end

    it 'shows success notification' do
      subject.call
      expect(flash[:success]).not_to be_empty
    end

    it 'saves current user as creator' do
      should change { Message.pluck(:creator_id) }.from([]).to([user.id])
    end
  end
end
