# frozen_string_literal: true

module Onboarding
  class SignalController < OnboardingController
    def splash; end

    private

    def attr_name
      :signal_phone_number
    end
  end
end
