# frozen_string_literal: true

module OnboardingHero
  class OnboardingHero < ApplicationComponent
    def initialize(image:, **)
      super

      @image = image
    end

    private

    attr_reader :image
  end
end
