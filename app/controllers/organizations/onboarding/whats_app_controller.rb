# frozen_string_literal: true

module Organizations
  module Onboarding
    class WhatsAppController < BaseController
      private

      def attr_name
        :whats_app_phone_number
      end

      def onboarding_allowed?
        @organization.channels_onboarding_allowed.include?(:whats_app)
      end
    end
  end
end
