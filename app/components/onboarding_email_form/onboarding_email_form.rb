# frozen_string_literal: true

module OnboardingEmailForm
  class OnboardingEmailForm < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor

    def data_protection_link
      Setting.onboarding_data_protection_link
    end
  end
end
