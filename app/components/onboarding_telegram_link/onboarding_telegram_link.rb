# frozen_string_literal: true

module OnboardingTelegramLink
  class OnboardingTelegramLink < ApplicationComponent
    def initialize(telegram_onboarding_token:, telegram_bot_username:, **)
      super

      @telegram_onboarding_token = telegram_onboarding_token
      @telegram_bot_username = telegram_bot_username
    end

    private

    attr_reader :telegram_onboarding_token, :telegram_bot_username

    def telegram_link
      "https://t.me/#{telegram_bot_username}?start=#{telegram_onboarding_token}"
    end
  end
end
