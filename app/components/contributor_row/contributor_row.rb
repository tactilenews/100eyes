# frozen_string_literal: true

module ContributorRow
  class ContributorRow < OrganizationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
      @styles << :inactive unless contributor.active?
    end

    private

    attr_reader :contributor

    def url
      contributor_path(contributor)
    end

    def channels
      contributor.channels.map(&:to_s).map(&:camelize).join(', ')
    end

    def compact?
      styles.include?(:compact)
    end
  end
end
