# frozen_string_literal: true

module OnboardingTelegramLink
  class OnboardingTelegramLink < ApplicationComponent
    def initialize(telegram_onboarding_token:, **)
      super

      @telegram_onboarding_token = telegram_onboarding_token
    end

    private

    attr_reader :telegram_onboarding_token

    def telegram_link
      "https://t.me/#{Setting.telegram_bot_username}?start=#{telegram_onboarding_token}"
    end
  end
end
