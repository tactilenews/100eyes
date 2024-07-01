# frozen_string_literal: true

module OnboardingFooter
  class OnboardingFooter < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization
  end
end
