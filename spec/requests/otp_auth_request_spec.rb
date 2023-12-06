# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OTP Auth', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { create(:user, email: 'zora@example.org', password: '12345678', otp_enabled: true) }

  describe 'GET /otp_auth' do
    subject { response }

    before { get otp_auth_path(as: user) }

    context 'if user is already signed in' do
      it { is_expected.to redirect_to(dashboard_path) }
    end
  end

  describe 'POST /otp_auth' do
    subject { response }

    before { post otp_auth_path(session: { otp: otp_param }) }

    context 'if user has not provided correct email and password' do
      let(:otp_param) { '123456' }

      it { is_expected.to redirect_to(sign_in_path) }
    end

    context 'if user has provided correct email and password' do
      before do
        post session_path(session: { email: 'zora@example.org', password: '12345678' })
        post otp_auth_path(session: { otp: otp_param })
      end

      context 'and incorrect OTP' do
        let(:otp_param) { 'INCORRECT' }

        it { is_expected.to have_http_status(:unauthorized) }
        it { is_expected.not_to have_current_user }
      end

      context 'and correct OTP' do
        let(:otp_param) { user.otp_code }

        it { is_expected.to redirect_to(dashboard_path) }
        it { is_expected.to have_current_user(user) }
      end
    end

    context 'if user has been inactive for 15 minutes' do
      before do
        post session_path(session: { email: 'zora@example.org', password: '12345678' })
        travel(15.minutes + 1.second) { post otp_auth_path(session: { otp: otp_param }) }
      end

      let(:otp_param) { user.otp_code }

      it { is_expected.to redirect_to(sign_in_path) }
      it { is_expected.not_to have_current_user }
    end
  end
end
