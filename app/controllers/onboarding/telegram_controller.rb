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
    end

    def fallback
      @telegram_onboarding_token = telegram_onboarding_token
    end

    private

    def redirect_to_success
      telegram_onboarding_token = @contributor.telegram_onboarding_token
      redirect_to organization_onboarding_telegram_link_path(@organization, telegram_onboarding_token: telegram_onboarding_token)
    end

    def attr_name
      :telegram_onboarding_token
    end

    def telegram_onboarding_token
      params.require(:telegram_onboarding_token)
    end

    def onboarding_allowed?
      @organization.channels_onboarding_allowed.include?(:telegram)
    end
  end
end
