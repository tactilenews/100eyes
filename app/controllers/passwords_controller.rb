# frozen_string_literal: true

class PasswordsController < Clearance::PasswordsController
  skip_before_action :ensure_otp_verified
end
