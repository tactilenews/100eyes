# frozen_string_literal: true

module ContributorQuickEditForm
  class ContributorQuickEditForm < ApplicationComponent
    def initialize(contributor:, organization:)
      super

      @contributor = contributor
      @organization = organization
    end

    private

    attr_reader :contributor, :organization

    def available_tags
      organization.all_tags_with_count.to_json
    end
  end
end
