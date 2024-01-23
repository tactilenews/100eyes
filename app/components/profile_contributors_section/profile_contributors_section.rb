# frozen_string_literal: true

module ProfileContributorsSection
  class ProfileContributorsSection < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization

    private

    def api_only_instance?
      configured_messengers_hash = Setting.channels.except('email')
      Setting.api_token.present? && configured_messengers_hash.values.all?(false)
    end
  end
end
