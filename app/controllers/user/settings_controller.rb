class User::SettingsController < ApplicationController
  skip_before_action :ensure_2fa_setup, only: [:two_factor_auth_setup, :verify_user_otp]

  def two_factor_auth_setup
    redirect_to dashboard_path if current_user.otp_enabled?
  
    @user = current_user
    qr_code
  end

  def verify_user_otp
    if current_user.authenticate_otp(two_factor_auth_params['otp_code_token'], drift: 30)
      current_user.update(otp_enabled: true)
      redirect_to dashboard_path
    else
      qr_code
      flash.now[:error] = I18n.t('components.two_factor_authentication.failure_message')
      render 'sessions/two_factor_authentication', status: :unauthorized
    end
  end

  private

  def two_factor_auth_params
    params.require(:user).permit(:otp_code_token)
  end

  def qr_code
    @qr_code ||= RQRCode::QRCode.new(current_user.provisioning_uri(Setting.project_name))
  end
end
