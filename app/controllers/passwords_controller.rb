# frozen_string_literal: true

class PasswordsController < Clearance::PasswordsController
  skip_before_action :require_login
  skip_before_action :require_otp_setup
end
