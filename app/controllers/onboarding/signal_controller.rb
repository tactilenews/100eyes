# frozen_string_literal: true

module Onboarding
  class SignalController < OnboardingController
    skip_before_action :verify_jwt, only: :link
    before_action :ensure_signal_is_set_up

    def link; end

    private

    def attr_name
      :signal_phone_number
    end

    def redirect_to_success
      redirect_to onboarding_signal_link_path(jwt: nil)
    end

    def ensure_signal_is_set_up
      return if Setting.signal_server_phone_number.present?

      raise ActionController::RoutingError, 'Not Found'
    end
  end
end
