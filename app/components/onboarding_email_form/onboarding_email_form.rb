# frozen_string_literal: true

module OnboardingEmailForm
  class OnboardingEmailForm < ApplicationComponent
    def initialize(contributor:, jwt:, **)
      super

      @contributor = contributor
      @jwt = jwt
    end

    private

    attr_reader :contributor, :jwt
  end
end
