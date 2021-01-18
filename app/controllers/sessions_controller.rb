# frozen_string_literal: true

class SessionsController < Clearance::SessionsController
  skip_before_action :require_login, only: %i[new destroy verify_user_email_and_password verify_user_otp], raise: false

  def verify_user_email_and_password
    @user = authenticate(params)

    if @user
      if @user.otp_enabled?
        cookies.encrypted[:sessions_user_id] = { value: @user.id, expires: 3.minutes }
        render 'sessions/two_factor_auth_verify_otp_form'
      else
        create_session
      end
    else
      redirect_to sign_in_path, flash: { error: I18n.t('flashes.failure_after_create') }
    end
  end

  def verify_user_otp
    @user = User.where(id: cookies.encrypted[:sessions_user_id]).first

    if @user&.authenticate_otp(verify_user_params['otp_code_token'], drift: 30)
      create_session
    else
      qr_code
      flash.now[:error] = I18n.t('components.two_factor_authentication.failure_message')
      render 'sessions/two_factor_auth_verify_otp_form', status: :unauthorized
    end
  end

  private

  def verify_user_params
    params.require(:session).permit(:otp_code_token)
  end

  def create_session
    sign_in(@user) do |status|
      if status.success?
        redirect_back_or url_after_create
      else
        redirect_to sign_in_path, flash: { alert: I18n.t('flashes.failure_when_not_signed_in') }
      end
    end
  end

  def qr_code
    @qr_code ||= RQRCode::QRCode.new(@user&.provisioning_uri(Setting.project_name).to_s)
  end
end
