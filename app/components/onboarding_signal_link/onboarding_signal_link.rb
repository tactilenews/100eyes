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

    def signal_link
      organization.signal_complete_onboarding_link
    end
  end
end
