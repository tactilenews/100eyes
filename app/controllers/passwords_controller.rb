# frozen_string_literal: true

class PasswordsController < Clearance::PasswordsController
  skip_before_action :require_login, :user_permitted?, :set_organization

  def update
    @user = find_user_for_update

    if @user.update_password(password_from_password_reset_params)
      @user.update_columns(must_reset_password: false)
      session[:password_reset_token] = nil
      redirect_to url_after_update, status: :see_other
    else
      flash_failure_after_update
      render template: 'passwords/edit', status: :unprocessable_entity
    end
  end

  private

  def url_after_update
    sign_in_path
  end
end
