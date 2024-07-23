# frozen_string_literal: true

module Onboarding
  class EmailController < OnboardingController
    private

    def attr_name
      :email
    end

    def onboarding_allowed?
      @organization.email_onboarding_allowed?
    end
  end
end
