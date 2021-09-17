# frozen_string_literal: true

module OnboardingTelegramFallback
  class OnboardingTelegramFallback < ApplicationComponent
    def initialize(telegram_onboarding_token:, **)
      super

      @telegram_onboarding_token = telegram_onboarding_token
    end

    private

    attr_reader :telegram_onboarding_token

    def fallback_steps
      data = { telegram_handle: Setting.telegram_bot_username, token: telegram_onboarding_token }
      I18n.t('components.onboarding_telegram_fallback.steps', **data)
    end
  end
end
