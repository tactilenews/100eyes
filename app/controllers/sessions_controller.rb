# frozen_string_literal: true

class SessionsController < Clearance::SessionsController
  before_action :load_user, only: :create, raise: false
  before_action :verify_otp_code, only: :create, if: -> { @user&.otp_enabled? }
  skip_before_action :ensure_2fa_setup

  private

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def load_user
    @user ||= authenticate(params)
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def verify_otp_code
    return if @user&.authenticate_otp(verify_user_params['otp_code'], drift: 30)

    flash.now[:alert] = I18n.t('flashes.failure_after_create')
    # Filter chain halted as :verify_otp_code rendered or redirected
    render :new, status: :unauthorized
  end

  def verify_user_params
    params.require(:session).permit(:otp_code, :email, :password)
  end
end
