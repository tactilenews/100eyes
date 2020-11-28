module Clearance
  class EmailConfirmationGuard < Clearance::SignInGuard
    def call
      if unconfirmed?
        failure("You must confirm your email address.")
      else
        next_guard
      end
    end
  
    def unconfirmed?
      signed_in? && !current_user.confirmed_at
    end
  end
end
