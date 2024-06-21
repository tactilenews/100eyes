# frozen_string_literal: true

module Onboarding
  class SignalController < OnboardingController
    skip_before_action :verify_jwt, only: :link

    def show
      super
      @contributor.signal_onboarding_token = SecureRandom.alphanumeric(8).upcase
    end

    def link
      @signal_onboarding_token = signal_onboarding_token
    end

    private

    def redirect_to_success
      signal_onboarding_token = @contributor.signal_onboarding_token
      redirect_to onboarding_signal_link_path(signal_onboarding_token: signal_onboarding_token, jwt: nil)
    end

    def attr_name
      :signal_onboarding_token
    end

    def signal_onboarding_token
      params.require(:signal_onboarding_token)
    end

    def onboarding_allowed?
      @organization.channels_onboarding_allowed.include?(:signal)
    end
  end
end
