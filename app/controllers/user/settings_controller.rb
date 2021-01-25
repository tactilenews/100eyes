# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class User::SettingsController < ApplicationController
  skip_before_action :ensure_2fa_setup, only: %i[two_factor_auth_setup enable_otp]
  before_action :ensure_otp_not_enabled, only: :two_factor_auth_setup

  def two_factor_auth_setup
    @user = current_user
    qr_code
  end

  def enable_otp
    if current_user.authenticate_otp(enable_otp_params['otp_code'], drift: 30)
      current_user.update(otp_enabled: true)
      redirect_to dashboard_path
    else
      qr_code
      flash.now[:error] = I18n.t('two_factor_authentication.failure_message')
      render 'user/settings/two_factor_auth_setup', status: :unauthorized
    end
  end

  private

  def ensure_otp_not_enabled
    redirect_to dashboard_path if current_user.otp_enabled?
  end

  def enable_otp_params
    params.require(:user).permit(:otp_code)
  end

  def qr_code
    @qr_code ||= RQRCode::QRCode.new(current_user.provisioning_uri(Setting.project_name))
  end
end
# rubocop:enable Style/ClassAndModuleChildren
