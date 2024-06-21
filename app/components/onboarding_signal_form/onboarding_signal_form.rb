# frozen_string_literal: true

module OnboardingSignalForm
  class OnboardingSignalForm < ApplicationComponent
    def initialize(organization:, contributor:, **)
      super

      @organization = organization
      @contributor = contributor
    end

    private

    attr_reader :organization, :contributor
  end
end
