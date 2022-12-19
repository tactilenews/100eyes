# frozen_string_literal: true

module OnboardingSignalLink
  class OnboardingSignalLink < ApplicationComponent
    private

    def url
      "whatsapp://send?phone=#{Setting.whats_app_server_phone_number}&text=#{URI.encode('imagine-funny')}"
    end
  end
end
