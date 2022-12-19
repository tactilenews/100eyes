# frozen_string_literal: true

module Onboarding
  class WhatsAppController < OnboardingController
    skip_before_action :verify_jwt, only: :link
    before_action :ensure_whats_app_is_set_up

    def link; end

    private

    def attr_name
      :whats_app_phone_number
    end

    def redirect_to_success
      redirect_to onboarding_whats_app_link_path(jwt: nil)
    end

    def ensure_whats_app_is_set_up
      return if Setting.whats_app_server_phone_number.present?

      raise ActionController::RoutingError, 'Not Found'
    end
  end
end
