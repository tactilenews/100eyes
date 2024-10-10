# frozen_string_literal: true

module WhatsAppSetup
  class WhatsAppSetup < ApplicationComponent
    def initialize(organization_id:)
      super

      @organization_id = organization_id
    end

    attr_reader :organization_id

    private

    def permissions_url
      "https://hub.360dialog.com/dashboard/app/#{ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_ID', '')}/permissions?redirect_url=#{CGI.escape(organization_whats_app_setup_successful_url(organization_id))}"
    end
  end
end
