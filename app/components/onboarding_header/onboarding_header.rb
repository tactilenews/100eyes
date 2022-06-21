# frozen_string_literal: true

module OnboardingHeader
  class OnboardingHeader < ApplicationComponent
    private

    def logo
      Setting.onboarding_logo
    end

    def logo?
      logo.present? && logo.image?
    end

    def project_name
      Setting.project_name
    end

    def byline
      Setting.onboarding_byline
    end
  end
end
