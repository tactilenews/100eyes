# frozen_string_literal: true

module OnboardingHero
  class OnboardingHero < ApplicationComponent
    def initialize(photo:, **)
      super

      @photo = photo
    end

    private

    attr_reader :photo
  end
end
