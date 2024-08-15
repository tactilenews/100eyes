# frozen_string_literal: true

module ContributorRow
  class ContributorRow < ApplicationComponent
    def initialize(organization:, contributor:, **)
      super

      @organization = organization
      @contributor = contributor
      @styles << :inactive unless contributor.active?
    end

    private

    attr_reader :organization, :contributor

    def url
      organization_contributor_path(organization, contributor)
    end

    def channels
      contributor.channels.map(&:to_s).map(&:camelize).join(', ')
    end

    def compact?
      styles.include?(:compact)
    end
  end
end
