# frozen_string_literal: true

class MustResetPasswordGuard < Clearance::SignInGuard
  def call
    if signed_in? && current_user.must_reset_password?
      current_user.forgot_password!
      failure(I18n.t('clearance.flashes.must_reset_password'))
    else
      next_guard
    end
  end
end
