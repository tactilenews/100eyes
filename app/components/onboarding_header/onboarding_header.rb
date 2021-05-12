# frozen_string_literal: true

module OnboardingHeader
  class OnboardingHeader < ApplicationComponent
    def initialize(logo:, **)
      super

      @logo = logo
    end

    private

    attr_reader :logo

    def project_name
      Setting.project_name
    end

    def byline
      Setting.onboarding_byline
    end
  end
end
