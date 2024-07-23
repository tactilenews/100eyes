# frozen_string_literal: true

module OnboardingTelegramFallback
  class OnboardingTelegramFallback < ApplicationComponent
    def initialize(organization:, telegram_onboarding_token:, **)
      super

      @organization = organization
      @telegram_onboarding_token = telegram_onboarding_token
    end

    private

    attr_reader :organization, :telegram_onboarding_token

    def fallback_steps
      data = { telegram_handle: organization.telegram_bot_username, token: telegram_onboarding_token }
      I18n.t('components.onboarding_telegram_fallback.steps', **data)
    end
  end
end
