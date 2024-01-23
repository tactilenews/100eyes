# frozen_string_literal: true

module OnboardingChannelsCheckboxes
  class OnboardingChannelsCheckboxes < ApplicationComponent
    private

    def configured_channels
      Setting.channels.select { |_key, value| value }
    end
  end
end
