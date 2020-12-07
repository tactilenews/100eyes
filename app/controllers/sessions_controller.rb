# frozen_string_literal: true

class SessionsController < Clearance::SessionsController
  before_action :verify_sign_in_jwt, only: :verify_user_otp
  skip_before_action :require_login, only: %i[new destroy verify_user_email_and_password verify_user_otp], raise: false

  def verify_user_email_and_password
    @user = authenticate(params)

    if @user
      payload = { user_id: @user.id, action: 'sign_in' }
      @jwt = JsonWebToken.encode(payload, expires_in: 3.minutes.from_now.to_i)
      @qr_code = RQRCode::QRCode.new(@user.provisioning_uri(Setting.project_name), size: 7, level: :h)
      render 'sessions/two_factor_authentication'
    else
      redirect_to sign_in_path, flash: { alert: I18n.t('flashes.failure_after_create') }
    end
  end

  def verify_user_otp
    decoded_token = JsonWebToken.decode(jwt_param)
    user_id = decoded_token.first['data']['user_id']
    @user = User.find(user_id)
    return unless @user

    authenticate_otp = @user.authenticate_otp(verify_user_params['otp_code_token'], drift: 60)
    if authenticate_otp
      @user.otp_module_enabled! if @user.otp_module_disabled?
      create_session(@user)
    else
      @jwt = jwt_param
      flash.now.alert = I18n.t('user.sign_in.two_factor_authentication.failure_message')
      render 'sessions/two_factor_authentication', status: :unauthorized
    end
  end

  private

  def verify_sign_in_jwt
    decoded_token = JsonWebToken.decode(jwt_param)

    if decoded_token.first['data']['action'] != 'sign_in' || decoded_token.first['data']['user_id'].blank?
      raise ActionController::BadRequest
    end
  rescue StandardError
    render 'onboarding/unauthorized', status: :unauthorized
  end

  def jwt_param
    params.require(:jwt)
  end

  def verify_user_params
    params.require(:session).permit(:otp_code_token)
  end

  def create_session(user)
    sign_in(user) do |status|
      if status.success?
        redirect_back_or url_after_create
      else
        redirect_to sign_in_path, flash: { alert: 'something went wrong, not sure what' }
      end
    end
  end
end
