# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Passwords' do
  let(:user) { create(:user) }

  before { ActionMailer::Base.deliveries.clear }

  describe 'create' do
    subject { post '/passwords', params: { password: { email: user.email } } }

    it 'add a confirmation token to the user' do
      expect { subject }.to change { user.reload.confirmation_token }.from(nil).to(String)
    end

    it 'sends an email' do
      subject
      expect_mailer_to_have_delivery(
        user.email,
        I18n.t('clearance.models.clearance_mailer.change_password'),
        user.confirmation_token
      )
    end
  end

  describe 'edit' do
    subject { get "/users/#{user.id}/password/edit?token=#{confirmation_token}" }

    before { user.forgot_password! }

    let(:confirmation_token) { "I'm not a user" }

    context 'User not found' do
      it 'render edit with alert' do
        subject
        expect(response).to be_successful
        expect(flash[:alert]).to eq(I18n.t('flashes.failure_when_forbidden'))
      end
    end

    context 'User found' do\
      let(:confirmation_token) { user.confirmation_token }

      it 'redirects to edit with session' do
        subject
        expect(response).to redirect_to(edit_user_password_path(user))
        expect(session[:password_reset_token]).to eq(user.confirmation_token)
      end
    end
  end

  describe 'update' do
    subject { patch "/users/#{user.id}/password", params: params }

    before { user.forgot_password! }

    let(:params) do
      {
        token: "I'm not a user",
        password_reset: {
          password: Faker::Internet.password(min_length: 8, max_length: 128),
          otp_code: user.otp_code
        }
      }
    end

    context 'User not found' do
      it 'render edit with alert' do
        subject
        expect(response).to be_successful
        expect(flash[:alert]).to eq(I18n.t('flashes.failure_when_forbidden'))
      end
    end

    context 'User found' do
      let(:params) do
        {
          token: user.confirmation_token,
          password_reset: {
            password: password,
            otp_code: otp_code
          }
        }
      end
      let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
      let(:otp_code) { '123456' }

      context 'Incorrect otp_code' do
        it 'renders alert message' do
          subject
          expect(flash.now[:alert]).to eq(I18n.t('flashes.failure_after_update'))
        end
      end

      context 'Password not long enough' do
        let(:password) { Faker::Internet.password(min_length: 1, max_length: 7) }
        let(:otp_code) { user.otp_code }

        it 'renders alert message' do
          subject
          expect(flash.now[:alert]).to eq(I18n.t('flashes.failure_after_update'))
        end
      end

      context 'Password too long' do
        let(:password) { Faker::Internet.password(min_length: 129) }
        let(:otp_code) { user.otp_code }

        it 'renders alert message' do
          subject
          expect(flash.now[:alert]).to eq(I18n.t('flashes.failure_after_update'))
        end
      end

      context 'Success' do
        let(:password) { Faker::Internet.password(min_length: 8, max_length: 128) }
        let(:otp_code) { user.otp_code }

        it 'redirects to dashboard and refreshes session/cookie data' do
          subject
          expect(response).to redirect_to(dashboard_path)
          expect(session[:password_reset_token]).to be_nil
          expect(cookies[:remember_token]).to eq(user.reload.remember_token)
        end
      end
    end
  end

  def expect_mailer_to_have_delivery(recipient, subject, body)
    expect(ActionMailer::Base.deliveries).not_to be_empty

    message = ActionMailer::Base.deliveries.any? do |email|
      email.to == [recipient] &&
        email.subject =~ /#{subject}/i &&
        email.decoded =~ /#{body}/
    end

    expect(message).to be
  end
end
