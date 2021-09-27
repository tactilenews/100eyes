# frozen_string_literal: true

module OnboardingSignalForm
  class OnboardingSignalForm < ApplicationComponent
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
