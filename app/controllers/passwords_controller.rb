# frozen_string_literal: true

class PasswordsController < Clearance::PasswordsController
  before_action :load_user
  before_action :verify_otp_code, only: :update, if: -> { @user.otp_enabled? }

  private

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def load_user
    @user ||= find_user_for_update
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def verify_otp_code
    return if @user&.authenticate_otp(verify_user_params['otp_code'], drift: 30)

    @qr_code = RQRCode::QRCode.new(@user.provisioning_uri(Setting.project_name))
    flash.now[:error] = I18n.t('components.two_factor_authentication.failure_message')
    # Filter chain halted as :verify_otp_code rendered or redirected
    render :edit, status: :unauthorized
  end

  def verify_user_params
    params.require(:password_reset).permit(:otp_code, :password)
  end
end
