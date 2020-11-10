# frozen_string_literal: true

module ContributorRow
  class ContributorRow < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
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
