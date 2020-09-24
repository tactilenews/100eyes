# frozen_string_literal: true

require 'rails_helper'
require 'telegram/bot/rspec/integration/rails'

RSpec.describe '/users', type: :request do
  let(:user) { create(:user) }
  let(:the_request) { create(:request) }

  describe 'GET /index' do
    it 'should be successful' do
      get users_url, headers: auth_headers
      expect(response).to be_successful
    end
  end

  describe 'GET /show' do
    it 'should be successful' do
      get user_url(user), headers: auth_headers
      expect(response).to be_successful
    end
  end

  describe 'GET /requests/:id' do
    it 'should be successful' do
      get user_request_path(id: the_request.id, user_id: user.id), headers: auth_headers
      expect(response).to be_successful
    end
  end

  describe 'PATCH /update' do
    let(:new_attrs) do
      {
        first_name: 'Zora',
        last_name: 'Zimmermann',
        phone: '012345678',
        zip_code: '12345',
        city: 'Musterstadt',
        note: '11 Jahre alt',
        email: 'zora@example.org',
        tag_list: 'programmer,student'
      }
    end

    subject { -> { patch user_url(user), params: { user: new_attrs }, headers: auth_headers } }

    it 'updates the requested user' do
      subject.call
      user.reload

      expect(user.first_name).to eq('Zora')
      expect(user.last_name).to eq('Zimmermann')
      expect(user.phone).to eq('012345678')
      expect(user.zip_code).to eq('12345')
      expect(user.city).to eq('Musterstadt')
      expect(user.note).to eq('11 Jahre alt')
      expect(user.email).to eq('zora@example.org')
      expect(user.tag_list).to eq(%w[programmer student])
    end

    context 'removing tags' do
      let(:updated_attrs) do
        { tag_list: 'ops' }
      end
      let(:user) { create(:user, tag_list: %w[dev ops]) }

      it 'is supported' do
        patch user_url(user), params: { user: updated_attrs }, headers: auth_headers
        user.reload
        expect(user.tag_list).to eq(['ops'])
        expect(User.all_tags.count).to eq(1)
      end
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
    subject { -> { delete user_url(user), headers: auth_headers } }
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
    subject do
      lambda do
        post message_user_url(user), params: { message: { text: 'Forgot to ask: How are you?' } }, headers: auth_headers
      end
    end

    describe 'given a user' do
      let(:params) { {} }
      let(:user) { create(:user, **params) }

      describe 'response' do
        before(:each) { subject.call }
        it { expect(response).to have_http_status(:bad_request) }
      end

      describe 'given an active request' do
        before(:each) { create(:message, request: the_request, recipient: user) }

        describe 'response' do
          before(:each) { subject.call }
          let(:newest_message) { Message.reorder(created_at: :desc).first }
          it do
            expect(response)
              .to redirect_to(
                user_request_path(
                  user_id: user.id,
                  id: the_request.id,
                  anchor: "chat-row-#{newest_message.id}"
                )
              )
          end
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
              'MessageMailer',
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
