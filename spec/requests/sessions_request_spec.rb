# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let(:organization) { create(:organization) }
  let!(:user) { create(:user, email: 'zora@example.org', password: '12345678', otp_enabled: otp_enabled, organization: organization) }
  let(:otp_enabled) { false }

  describe 'GET /sign_in' do
    before(:each) { get sign_in_path(as: user) }
    subject { response }

    context 'if user is already signed-in' do
      it { should redirect_to(organizations_path) }
    end
  end

  describe 'POST /sessions' do
    before(:each) { post session_path(session: { email: email_param, password: password_param }) }
    subject { response }
    let(:email_param) { 'zora@example.org' }

    context 'with OTP disabled' do
      context 'with incorrect email and password' do
        let(:password_param) { 'abcdefgh' }

        it { should have_http_status(:unauthorized) }
        it { should_not have_current_user }
      end

      context 'with correct email and password' do
        let(:password_param) { '12345678' }

        it { should redirect_to(organizations_path) }
        it { should have_current_user(user) }
      end
    end

    context 'with OTP enabled' do
      let(:otp_enabled) { true }

      context 'with incorrect email and password' do
        let(:password_param) { 'abcdefgh' }

        it { should have_http_status(:unauthorized) }
        it { should_not have_current_user }
      end

      context 'with correct email and password' do
        let(:password_param) { '12345678' }

        it { should redirect_to(otp_auth_path) }
        it { should_not have_current_user }
      end
    end
  end
end
