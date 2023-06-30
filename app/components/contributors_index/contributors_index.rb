# frozen_string_literal: true

module ContributorsIndex
  class ContributorsIndex < ApplicationComponent
    def initialize(contributors:, state:, active_count:, inactive_count:, tag_list: nil)
      super

      @contributors = contributors
      @tag_list = tag_list
      @state = state
      @active_count = active_count
      @inactive_count = inactive_count
    end

    private

    attr_reader :contributors, :tag_list, :state, :active_count, :inactive_count

    def available_tags
      Contributor.all_tags_with_count.to_json
    end
  end
end
