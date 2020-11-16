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
      channels = []
      channels << :mail if contributor.email?
      channels << :telegram if contributor.telegram?
      channels
    end
  end
end
