# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let!(:user) { create(:user, email: 'zora@example.org', password: '12345678', otp_enabled: otp_enabled) }
  let(:otp_enabled) { false }

  describe 'GET /sign_in' do
    subject { response }

    before { get sign_in_path(as: user) }

    context 'if user is already signed-in' do
      it { is_expected.to redirect_to(dashboard_path) }
    end
  end

  describe 'POST /sessions' do
    subject { response }

    before { post session_path(session: { email: email_param, password: password_param }) }

    let(:email_param) { 'zora@example.org' }

    context 'with OTP disabled' do
      context 'with incorrect email and password' do
        let(:password_param) { 'abcdefgh' }

        it { is_expected.to have_http_status(:unauthorized) }
        it { is_expected.not_to have_current_user }
      end

      context 'with correct email and password' do
        let(:password_param) { '12345678' }

        it { is_expected.to redirect_to(dashboard_path) }
        it { is_expected.to have_current_user(user) }
      end
    end

    context 'with OTP enabled' do
      let(:otp_enabled) { true }

      context 'with incorrect email and password' do
        let(:password_param) { 'abcdefgh' }

        it { is_expected.to have_http_status(:unauthorized) }
        it { is_expected.not_to have_current_user }
      end

      context 'with correct email and password' do
        let(:password_param) { '12345678' }

        it { is_expected.to redirect_to(otp_auth_path) }
        it { is_expected.not_to have_current_user }
      end
    end
  end
end
