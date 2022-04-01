# frozen_string_literal: true

module OnboardingSignalForm
  class OnboardingSignalForm < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
