# frozen_string_literal: true

module ContributorsList
  class ContributorsList < OrganizationComponent
    def initialize(contributors:, filter_active: false, **)
      super

      @contributors = contributors
      @filter_active = filter_active
    end

    private

    attr_reader :contributors, :filter_active
  end
end
