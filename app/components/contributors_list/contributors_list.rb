# frozen_string_literal: true

module ContributorsList
  class ContributorsList < ApplicationComponent
    def initialize(organization:, contributors:, filter_active: false)
      super

      @organization = organization
      @contributors = contributors
      @filter_active = filter_active
    end

    private

    attr_reader :organization, :contributors, :filter_active
  end
end
