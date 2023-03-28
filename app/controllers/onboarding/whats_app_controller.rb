# frozen_string_literal: true

module Onboarding
  class WhatsAppController < OnboardingController
    before_action :ensure_whats_app_is_set_up

    private

    def attr_name
      :whats_app_phone_number
    end

    def ensure_whats_app_is_set_up
      return if Setting.whats_app_server_phone_number.present?

      raise ActionController::RoutingError, 'Not Found'
    end
  end
end
