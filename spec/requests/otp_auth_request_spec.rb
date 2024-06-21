# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OTP Auth', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { create(:user, email: 'zora@example.org', password: '12345678', otp_enabled: true) }
  before { create(:organization) }

  describe 'GET /otp_auth' do
    before(:each) { get otp_auth_path(as: user) }
    subject { response }

    context 'if user is already signed in' do
      it { should redirect_to(dashboard_path) }
    end
  end

  describe 'POST /otp_auth' do
    before(:each) { post otp_auth_path(session: { otp: otp_param }) }
    subject { response }

    context 'if user has not provided correct email and password' do
      let(:otp_param) { '123456' }
      it { should redirect_to(sign_in_path) }
    end

    context 'if user has provided correct email and password' do
      before(:each) do
        post session_path(session: { email: 'zora@example.org', password: '12345678' })
        post otp_auth_path(session: { otp: otp_param })
      end

      context 'and incorrect OTP' do
        let(:otp_param) { 'INCORRECT' }

        it { should have_http_status(:unauthorized) }
        it { should_not have_current_user }
      end

      context 'and correct OTP' do
        let(:otp_param) { user.otp_code }

        it { should redirect_to(dashboard_path) }
        it { should have_current_user(user) }
      end
    end

    context 'if user has been inactive for 15 minutes' do
      before(:each) do
        post session_path(session: { email: 'zora@example.org', password: '12345678' })
        travel(15.minutes + 1.second) { post otp_auth_path(session: { otp: otp_param }) }
      end

      let(:otp_param) { user.otp_code }

      it { should redirect_to(sign_in_path) }
      it { should_not have_current_user }
    end
  end
end
