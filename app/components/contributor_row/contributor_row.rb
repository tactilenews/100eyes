# frozen_string_literal: true

module ContributorRow
  class ContributorRow < ApplicationComponent
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

    def channel_icons
      contributor.channels
    end
  end
end
