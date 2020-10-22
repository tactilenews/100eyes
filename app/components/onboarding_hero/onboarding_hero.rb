# frozen_string_literal: true

module OnboardingHero
  class OnboardingHero < ApplicationComponent
    def initialize(photo:, heading:, **)
      super

      @photo = photo
      @heading = heading
    end

    private

    attr_reader :photo, :heading
  end
end
