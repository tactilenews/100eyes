# frozen_string_literal: true

module Organizations
  module Onboarding
    class EmailController < BaseController
      private

      def attr_name
        :email
      end

      def onboarding_allowed?
        @organization.email_onboarding_allowed?
      end
    end
  end
end
