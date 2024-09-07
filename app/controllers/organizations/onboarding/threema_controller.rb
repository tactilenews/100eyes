# frozen_string_literal: true

module Organizations
  module Onboarding
    class ThreemaController < BaseController
      private

      def attr_name
        :threema_id
      end

      def onboarding_allowed?
        @organization.channels_onboarding_allowed.include?(:threema)
      end
    end
  end
end
