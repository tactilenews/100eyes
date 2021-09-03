# frozen_string_literal: true

class SessionsController < Clearance::SessionsController
  skip_before_action :ensure_otp_verified
end
