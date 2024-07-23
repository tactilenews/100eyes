# frozen_string_literal: true

module OnboardingHeader
  class OnboardingHeader < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization

    private

    def logo
      blob = organization.onboarding_logo

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
      organization.project_name
    end

    def byline
      organization.onboarding_byline
    end
  end
end
