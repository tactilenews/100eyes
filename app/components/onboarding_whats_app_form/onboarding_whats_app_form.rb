# frozen_string_literal: true

module OnboardingWhatsAppForm
  class OnboardingWhatsAppForm < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
