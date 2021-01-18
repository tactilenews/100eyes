# frozen_string_literal: true

class PasswordsController < Clearance::PasswordsController
  def update
    @user = find_user_for_update

    if @user.update_password(password_from_password_reset_params)
      cookies.encrypted[:sessions_user_id] = { value: @user.id, expires: 3.minutes }
      qr_code
      render 'sessions/two_factor_auth_verify_otp_form'
      session[:password_reset_token] = nil
    else
      flash_failure_after_update
      render template: 'passwords/edit'
    end
  end

  private

  def qr_code
    @qr_code ||= RQRCode::QRCode.new(@user.provisioning_uri(Setting.project_name))
  end
end
