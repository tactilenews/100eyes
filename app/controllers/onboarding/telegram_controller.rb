# frozen_string_literal: true

require 'securerandom'

module Onboarding
  class TelegramController < OnboardingController
    skip_before_action :verify_jwt, only: %i[link fallback]

    def show
      super
      @contributor.telegram_onboarding_token = SecureRandom.alphanumeric(8).upcase
    end

    def link
      @telegram_onboarding_token = telegram_onboarding_token
      @telegram_bot_username = @organization.telegram_bot_username || Setting.telegram_bot_username
    end

    def fallback
      @telegram_onboarding_token = telegram_onboarding_token
      @telegram_bot_username = @organization.telegram_bot_username || Setting.telegram_bot_username
    end

    private

    def redirect_to_success
      telegram_onboarding_token = @contributor.telegram_onboarding_token
      redirect_to onboarding_telegram_link_path(telegram_onboarding_token: telegram_onboarding_token)
    end

    def attr_name
      :telegram_onboarding_token
    end

    def telegram_onboarding_token
      params.require(:telegram_onboarding_token)
    end
  end
end
