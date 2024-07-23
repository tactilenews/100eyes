# frozen_string_literal: true

module OnboardingTelegramLink
  class OnboardingTelegramLink < ApplicationComponent
    def initialize(organization:, telegram_onboarding_token:, **)
      super

      @organization = organization
      @telegram_onboarding_token = telegram_onboarding_token
    end

    private

    attr_reader :organization, :telegram_onboarding_token

    def telegram_link
      "https://t.me/#{organization.telegram_bot_username}?start=#{telegram_onboarding_token}"
    end
  end
end
