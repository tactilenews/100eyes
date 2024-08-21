# frozen_string_literal: true

module OnboardingChannelButtons
  class OnboardingChannelButtons < ApplicationComponent
    private

    def initialize(organization:, channels:)
      super

      @organization = organization
      @channels = channels
    end

    attr_reader :channels, :organization

    def styles
      return super + [:twoColumn] if channels.length.even?

      super
    end
  end
end
