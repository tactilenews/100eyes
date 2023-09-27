# frozen_string_literal: true

module ContributorsIndex
  class ContributorsIndex < ApplicationComponent
    def initialize(contributors:, state:, active_count:, inactive_count:, filter_count:, tag_list: nil)
      super

      @contributors = contributors
      @tag_list = tag_list
      @state = state
      @active_count = active_count
      @inactive_count = inactive_count
      @filter_count = filter_count
    end

    private

    attr_reader :contributors, :tag_list, :state, :active_count, :inactive_count, :filter_count

    def available_tags
      Contributor.all_tags_with_count.to_json
    end

    def active_contributors_count
      tag_list.present? && state == :active ? filter_count : active_count
    end

    def inactive_contributors_count
      tag_list.present? && state == :inactive ? filter_count : inactive_count
    end
  end
end
