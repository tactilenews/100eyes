# frozen_string_literal: true

module OnboardingHeader
  class OnboardingHeader < ApplicationComponent
    private

    def logo
      blob = Setting.onboarding_logo

      return nil if blob.blank?

      if blob.image? && blob.variable?
        blob.variant(resize_to_limit: [nil, 100])
      elsif blob.image?
        blob
      end
    end

    def logo?
      logo.present?
    end

    def project_name
      Setting.project_name
    end

    def byline
      Setting.onboarding_byline
    end
  end
end
