# frozen_string_literal: true

module OnboardingEmailForm
  class OnboardingEmailForm < ApplicationComponent
    def initialize(user:, jwt:, **)
      super

      @user = user
      @jwt = jwt
    end

    private

    attr_reader :user, :jwt
  end
end
