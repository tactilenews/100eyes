# frozen_string_literal: true

module OnboardingThreemaForm
  class OnboardingThreemaForm < ApplicationComponent
    def initialize(**)
      super

      @contributor = Contributor.new
    end
  end
end
