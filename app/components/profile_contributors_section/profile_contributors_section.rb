# frozen_string_literal: true

module ProfileContributorsSection
  class ProfileContributorsSection < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization
  end
end
