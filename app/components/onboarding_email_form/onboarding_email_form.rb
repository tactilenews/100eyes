# frozen_string_literal: true

module OnboardingEmailForm
  class OnboardingEmailForm < ApplicationComponent
    def initialize(user:, **)
      super

      @user = user
    end

    private

    attr_reader :user
  end
end
