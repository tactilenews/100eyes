# frozen_string_literal: true

module ProfileHeader
  class ProfileHeader < ApplicationComponent
    def initialize(organization:, **)
      super

      @organization = organization
    end

    attr_reader :organization
  end
end
