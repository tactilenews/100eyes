# frozen_string_literal: true

module OnboardingSuccess
  class OnboardingSuccess < ApplicationComponent
    def initialize(title:, text:, **)
      super

      @title = title
      @text = text
    end

    private

    attr_reader :title, :text
  end
end
