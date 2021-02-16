# frozen_string_literal: true

module TelegramWidget
  class TelegramWidget < ApplicationComponent
    def initialize(jwt:)
      super

      @jwt = jwt
    end

    private

    attr_reader :jwt

    def redirect_url
      "https://#{Setting.application_host}/onboarding/telegram/callback?jwt=#{jwt}"
    end
  end
end
