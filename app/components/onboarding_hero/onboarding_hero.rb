# frozen_string_literal: true

module OnboardingHero
  class OnboardingHero < ApplicationComponent
    private

    def hero
      Setting.onboarding_hero
    end

    def hero?
      hero.present? && hero.image?
    end
  end
end
