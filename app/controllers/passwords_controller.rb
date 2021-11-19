# frozen_string_literal: true

class PasswordsController < Clearance::PasswordsController
  skip_before_action :require_login
  skip_before_action :require_otp_setup

  def update
    # This method is almost completely copied from `Clearance::PasswordsController`.
    # However, in contrast to the parent class, it doesn't automatically sign in
    # a user after a successful password reset.
    @user = find_user_for_update

    if @user.update_password(password_from_password_reset_params)
      redirect_to sign_in_path
      session[:password_reset_token] = nil
    else
      flash_failure_after_update
      render template: 'passwords/edit'
    end
  end
end
