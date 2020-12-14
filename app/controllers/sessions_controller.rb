# frozen_string_literal: true

class SessionsController < Clearance::SessionsController
  skip_before_action :require_login, only: %i[new destroy verify_user_email_and_password verify_user_otp], raise: false

  def verify_user_email_and_password
    @user = authenticate(params)

    if @user
      cookies.encrypted[:sessions_user_id] = { value: @user.id, expires: 3.minutes }
      qr_code
      render 'sessions/two_factor_authentication'
    else
      redirect_to sign_in_path, flash: { error: I18n.t('flashes.failure_after_create') }
    end
  end

  def verify_user_otp
    @user = User.find(cookies.encrypted[:sessions_user_id])

    if @user.authenticate_otp(verify_user_params['otp_code_token'], drift: 30)
      @user.otp_module_enabled! if @user.otp_module_disabled?
      create_session
    else
      qr_code
      flash.now[:error] = I18n.t('user.sign_in.two_factor_authentication.failure_message')
      render 'sessions/two_factor_authentication', status: :unauthorized
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
        redirect_to sign_in_path, flash: { alert: 'something went wrong, not sure what' }
      end
    end
  end

  def qr_code
    @qr_code ||= RQRCode::QRCode.new(@user.provisioning_uri(Setting.project_name))
  end
end
