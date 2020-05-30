# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe '/users', type: :request do
  let(:user) { create(:user) }

  describe 'GET /index' do
    it 'should be successful' do
      get users_url
      expect(response).to be_successful
    end
  end

  describe 'GET /show' do
    it 'should be successful' do
      get user_url(user)
      expect(response).to be_successful
    end
  end

  describe 'GET /requests/:id' do
    let(:request) { create(:request) }

    it 'should be successful' do
      get user_request_path(id: request.id, user_id: user.id)
      expect(response).to be_successful
    end
  end

  describe 'PATCH /update' do
    let(:new_attrs) { { name: 'Zora Zimmermann', note: '11 Jahre alt', email: 'zora@example.org' } }
    subject { -> { patch user_url(user), params: { user: new_attrs } } }

    it 'updates the requested user' do
      subject.call
      user.reload

      expect(user.first_name).to eq('Zora')
      expect(user.last_name).to eq('Zimmermann')
      expect(user.note).to eq('11 Jahre alt')
      expect(user.email).to eq('zora@example.org')
    end

    it 'redirects to the user' do
      subject.call
      expect(response).to redirect_to(user_url(user))
    end

    it 'shows success message' do
      subject.call
      expect(flash[:success]).to eq('Informationen zu Zora Zimmermann gespeichert')
    end
  end

  describe 'DELETE /destroy' do
    subject { -> { delete user_url(user) } }
    before(:each) { user }

    it 'destroys the requested user' do
      expect { subject.call }.to change(User, :count).by(-1)
    end

    it 'redirects to the users list' do
      subject.call
      expect(response).to redirect_to(users_url)
    end
  end

  describe 'POST /message', telegram_bot: :rails do
    subject { -> { post user_message_url(user), params: { message: { text: 'Forgot to ask: How are you?' } } } }

    describe 'given a user' do
      let(:params) { {} }
      let(:user) { create(:user, **params) }

      describe 'response' do
        before(:each) { subject.call }
        it { expect(response).to have_http_status(:bad_request) }
      end

      describe 'given an active request' do
        let(:request) { create(:request) }
        before(:each) { request }

        describe 'response' do
          before(:each) { subject.call }
          it { expect(response).to redirect_to(user_request_path(user_id: user.id, id: request.id)) }
        end

        describe 'with a `telegram_chat_id`' do
          let(:params) { { email: nil, telegram_id: 3, telegram_chat_id: 4 } }
          let(:chat_id) { 4 }
          let(:expected_message) { 'Forgot to ask: How are you?' }
          it { should respond_with_message expected_message }
          it { should_not have_enqueued_job.on_queue('mailers') }
        end

        describe 'with an `email`' do
          let(:params) { { email: 'user@example.org' } }
          it { should_not respond_with_message }
          it {
            should have_enqueued_job.on_queue('mailers').with(
              'QuestionMailer',
              'new_message_email',
              'deliver_now',
              {
                params: {
                  message: 'Forgot to ask: How are you?',
                  to: 'user@example.org'
                },
                args: []
              }
            )
          }
        end
      end
    end
  end
end
