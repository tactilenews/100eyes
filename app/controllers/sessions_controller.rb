# frozen_string_literal: true

class SessionsController < Clearance::SessionsController
  before_action :verify_user_params, only: :verify_user
  before_action :set_user, only: :verify_user
  skip_before_action :require_login, only: %i[create new destroy verify_user], raise: false

  def create
    @user = authenticate(params)

    return unless @user

    @qr_code = RQRCode::QRCode.new(@user.provisioning_uri(Setting.project_name), size: 7, level: :h)
    render 'sessions/two_factor_authentication'
  end

  def verify_user
    return unless @user

    authenticate_otp = @user&.authenticate_otp(verify_user_params['otp_code_token'], drift: 60)
    return unless authenticate_otp

    @user.otp_module_enabled! if @user.otp_module_disabled?

    sign_in(@user) do |status|
      if status.success?
        redirect_back_or url_after_create
      else
        flash.now.alert = status.failure_message
        render template: 'sessions/new', status: :unauthorized
      end
    end
  end

  private

  def verify_user_params
    params.require(:session).permit(:otp_code_token, :user_id)
  end

  def set_user
    @user = User.find(params[:user_id])
  end
end
