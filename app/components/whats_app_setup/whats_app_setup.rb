# frozen_string_literal: true

module WhatsAppSetup
  class WhatsAppSetup < ApplicationComponent
    private

    def permissions_url
      "https://hub.360dialog.com/dashboard/app/#{ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_ID', '')}/permissions?redirect_url=#{CGI.escape(whats_app_onboarding_successful_url)}"
    end
  end
end
