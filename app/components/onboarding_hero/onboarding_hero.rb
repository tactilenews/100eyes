# frozen_string_literal: true

module OnboardingHero
  class OnboardingHero < ApplicationComponent
    private

    def hero
      blob = Setting.onboarding_hero

      blob.variant(resize_to_fill: [900, 450], quality: 65, convert: 'jpeg') if blob.present? && blob.variable?
    end

    def hero?
      hero.present?
    end
  end
end
