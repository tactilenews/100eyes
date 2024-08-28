# frozen_string_literal: true

class SessionsController < Clearance::SessionsController
  skip_before_action :require_login, :require_otp_setup, :user_permitted?, :set_organization

  def create
    user = authenticate(params)

    if user&.otp_enabled?
      session[:otp_user_id] = user.id
      session[:otp_start_time] = Time.zone.now

      redirect_to otp_auth_path
    else
      sign_in(user)
    end
  end
end
