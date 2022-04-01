# frozen_string_literal: true

module OnboardingThreemaForm
  class OnboardingThreemaForm < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
