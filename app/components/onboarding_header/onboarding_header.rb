# frozen_string_literal: true

module OnboardingHeader
  class OnboardingHeader < ApplicationComponent
    def initialize(logo:, **)
      super

      @logo = logo
    end

    private

    attr_reader :logo
  end
end
