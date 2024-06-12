# frozen_string_literal: true

module OnboardingSignalLink
  class OnboardingSignalLink < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization

    def signal_server_phone_number
      organization.signal_server_phone_number || Setting.signal_server_phone_number
    end
  end
end
