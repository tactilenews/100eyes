# frozen_string_literal: true

module OnboardingEmailForm
  class OnboardingEmailForm < ApplicationComponent
    def initialize(user:, token:, **)
      super

      @user = user
      @token = token
    end

    private

    attr_reader :user, :token
  end
end
