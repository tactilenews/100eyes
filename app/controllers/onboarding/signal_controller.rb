# frozen_string_literal: true

module Onboarding
  class SignalController < OnboardingController
    skip_before_action :verify_jwt, only: :link

    def link; end

    private

    def attr_name
      :signal_phone_number
    end

    def redirect_to_success
      redirect_to onboarding_signal_link_path(jwt: nil)
    end
  end
end
