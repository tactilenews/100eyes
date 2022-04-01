# frozen_string_literal: true

module OnboardingTelegramForm
  class OnboardingTelegramForm < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
