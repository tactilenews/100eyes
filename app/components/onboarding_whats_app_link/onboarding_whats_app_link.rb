# frozen_string_literal: true

module OnboardingWhatsAppLink
  class OnboardingWhatsAppLink < ApplicationComponent
    private

    def open_app
      "whatsapp://send?phone=#{Setting.whats_app_server_phone_number}&text=#{CGI.escape('join imagine-funny')}"
    end

    def whats_app_web_url
      "https://web.whatsapp.com/send?phone=#{Setting.whats_app_server_phone_number}&text=#{CGI.escape('join imagine-funny')}"
    end
  end
end
