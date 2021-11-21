# frozen_string_literal: true

module ContributorQuickEditForm
  class Component < ApplicationComponent
    def initialize(contributor:)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor

    def available_tags
      Contributor.all_tags_with_count.to_json
    end
  end
end
