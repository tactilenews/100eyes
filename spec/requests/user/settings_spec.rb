# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User::Settings' do
  let(:user) { create(:user, otp_enabled: false) }

  describe 'GET /user/settings/:id/two_factor_auth_setup' do
    subject { get two_factor_auth_setup_user_setting_path(user, as: user) }

    let(:rqr_code) { instance_double(RQRCode::QRCode, as_svg: '<svg></svg>') }

    it 'is successful' do
      subject
      expect(response).to be_successful
    end

    it 'creates a QR code with the user provisioning_uri and project name' do
      expect(RQRCode::QRCode).to receive(:new).with(user.provisioning_uri(user.email, issuer: Setting.application_host)).and_return(rqr_code)

      subject
    end

    context '2fa already setup' do
      before { user.update(otp_enabled: true) }

      it 'redirects a user if they already have enabled 2fa' do
        subject
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe 'PATCH /user/settings/:id/enable_otp' do
    subject { patch enable_otp_user_setting_path(user, as: user), params: { user: { otp_code: otp_code } } }

    let(:otp_code) { SecureRandom.hex(3) }

    before { subject }

    it 'Invalid otp_code' do
      expect(response).to be_unauthorized
    end

    it 'displays error message' do
      expect(response.request.flash[:error]).to eq(I18n.t('two_factor_authentication.failure_message'))
    end

    context 'Authorized' do
      let(:otp_code) { user.otp_code }

      it 'valid otp_code' do
        subject
        expect(response).to redirect_to('/dashboard')
      end

      it 'sets remember_token for user' do
        subject
        expect(response.cookies['remember_token']).to eq(user.remember_token)
      end
    end
  end
end
