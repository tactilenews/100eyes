# frozen_string_literal: true

require 'securerandom'

module Onboarding
  class TelegramController < ChannelController
    skip_before_action :verify_jwt, only: %i[link fallback]
    before_action :ensure_contributor_exists, only: %i[link fallback]

    def show
      super
      @contributor.telegram_onboarding_token = SecureRandom.alphanumeric(8)
    end

    def link
      @telegram_onboarding_token = contributor.telegram_onboarding_token
    end

    def fallback
      @telegram_onboarding_token = contributor.telegram_onboarding_token
    end

    private

    def contributor
      @contributor ||= Contributor.find_by(telegram_onboarding_params)
    end

    def ensure_contributor_exists
      render 'onboarding/unauthorized', status: :unauthorized unless contributor
    end

    def redirect_to_success
      telegram_onboarding_token = contributor.telegram_onboarding_token
      redirect_to onboarding_telegram_link_path(jwt: nil, telegram_onboarding_token: telegram_onboarding_token)
    end

    def attr_name
      :telegram_onboarding_token
    end

    def telegram_onboarding_params
      params.permit(:telegram_onboarding_token).merge(telegram_id: nil)
    end
  end
end
