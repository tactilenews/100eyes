# frozen_string_literal: true

class SessionsController < Clearance::SessionsController
  before_action :load_user
  before_action :verify_otp_code, only: :create, if: -> { @user&.otp_enabled? }

  private

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def load_user
    @user ||= authenticate(params)
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def verify_otp_code
    return if @user&.authenticate_otp(verify_user_params['otp_code'], drift: 30)

    flash.now[:error] = I18n.t('components.two_factor_authentication.failure_message')
    # Filter chain halted as :verify_otp_code rendered or redirected
    render :new, status: :unauthorized
  end

  def verify_user_params
    params.require(:session).permit(:otp_code, :email, :password)
  end
end
