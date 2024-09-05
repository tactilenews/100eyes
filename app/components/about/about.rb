# frozen_string_literal: true

module About
  class About < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization

    private

    def version
      ENV.fetch('GIT_COMMIT_SHA', nil)[0, 8]
    end

    def date
      date_time(ENV.fetch('GIT_COMMIT_DATE', nil).to_date, format: :default)
    end

    def channel_status(channel)
      set_up = case channel
               when :email
                 organization.email_from_address
               when :threema
                 organization.threemarb_api_identity
               when :signal
                 organization.signal_server_phone_number&.phony_formatted
               when :telegram
                 organization.telegram_bot_username
               when :whats_app
                 organization.whats_app_server_phone_number&.phony_formatted
               end
      "#{set_up || t('.not_set_up')}: (#{channel_active(channel)})"
    end

    def channel_active(channel)
      organization.channels_onboarding_allowed.include?(channel) ? t('.active') : t('.inactive')
    end
  end
end
