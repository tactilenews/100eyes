# frozen_string_literal: true

module OnboardingSignalLink
  class OnboardingSignalLink < ApplicationComponent
    def initialize(organization:, signal_onboarding_token:, **)
      super

      @organization = organization
      @signal_onboarding_token = signal_onboarding_token
    end

    private

    attr_reader :organization, :signal_onboarding_token

    def fallback_steps
      data = { signal_server_phone_number: organization.signal_server_phone_number, token: signal_onboarding_token }
      I18n.t('components.onboarding_signal_link.steps', **data)
    end
  end
end
