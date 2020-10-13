# frozen_string_literal: true

module OnboardingSuccess
  class OnboardingSuccess < ApplicationComponent
    def initialize(heading:, text:, **)
      super

      @heading = heading
      @text = text
    end

    private

    attr_reader :heading, :text
  end
end
