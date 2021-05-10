# frozen_string_literal: true

require 'securerandom'

module Onboarding
  class TelegramController < ChannelController
    skip_before_action :verify_jwt, only: :link

    def show
      super
      @contributor.telegram_onboarding_token = SecureRandom.alphanumeric(8)
    end

    def link
      contributor = Contributor.find_by!(telegram_id: nil, telegram_onboarding_token: params[:telegram_onboarding_token])
      @telegram_onboarding_token = contributor.telegram_onboarding_token
    end

    private

    def redirect_to_success
      telegram_onboarding_token = @contributor.telegram_onboarding_token
      redirect_to onboarding_telegram_link_path(jwt: nil, telegram_onboarding_token: telegram_onboarding_token)
    end

    def attr_name
      :telegram_onboarding_token
    end
  end
end
