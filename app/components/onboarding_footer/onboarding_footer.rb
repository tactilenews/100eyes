# frozen_string_literal: true

module OnboardingFooter
  class OnboardingFooter < ApplicationComponent
    def initialize(imprint_link:, **)
      super

      @imprint_link = imprint_link
    end

    private

    attr_reader :imprint_link
  end
end
