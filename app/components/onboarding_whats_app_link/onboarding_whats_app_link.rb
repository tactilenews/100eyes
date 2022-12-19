# frozen_string_literal: true

module OnboardingWhatsAppLink
  class OnboardingWhatsAppLink < ApplicationComponent
    private

    def url
      "https://web.whatsapp.com/send?phone=#{Setting.whats_app_server_phone_number}&text=#{CGI.escape('imagine-funny')}"
    end
  end
end
