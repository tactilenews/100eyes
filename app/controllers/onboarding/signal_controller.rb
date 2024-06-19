# frozen_string_literal: true

module Onboarding
  class SignalController < OnboardingController
    skip_before_action :verify_jwt, only: :link

    def link; end

    private

    def attr_name
      :signal_phone_number
    end
  end
end
