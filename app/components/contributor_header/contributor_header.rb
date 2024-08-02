# frozen_string_literal: true

module ContributorHeader
  class ContributorHeader < OrganizationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
