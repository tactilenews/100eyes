# frozen_string_literal: true

module ContributorQuickEditForm
  class ContributorQuickEditForm < ApplicationComponent
    def initialize(organization:, contributor:)
      super

      @organization = organization
      @contributor = contributor
    end

    private

    attr_reader :organization, :contributor

    def available_tags
      organization.contributors_tags_with_count.to_json
    end
  end
end
