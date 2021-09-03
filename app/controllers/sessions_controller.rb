# frozen_string_literal: true

class SessionsController < Clearance::SessionsController
  skip_before_action :ensure_otp_is_verified, :ensure_otp_is_set_up
end
