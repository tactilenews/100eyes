# frozen_string_literal: true

module OnboardingChannelButtons
  class OnboardingChannelButtons < ApplicationComponent
    private

    def initialize(channels:)
      super

      @channels = channels
    end

    attr_reader :channels

    def styles
      return super + [:twoColumn] if channels.length.even?

      super
    end
  end
end
