# frozen_string_literal: true

module ContributorsIndex
  class ContributorsIndex < OrganizationComponent
    def initialize(contributors:, state:, active_count:, inactive_count:, unsubscribed_count:, filter_count:, available_tags:, tag_list: nil, **)
      super

      @contributors = contributors
      @tag_list = tag_list
      @state = state
      @active_count = active_count
      @inactive_count = inactive_count
      @unsubscribed_count = unsubscribed_count
      @filter_count = filter_count
      @available_tags = available_tags
    end

    private

    attr_reader :contributors, :tag_list, :state, :active_count, :inactive_count, :unsubscribed_count, :filter_count, :available_tags

    def active_contributors_count
      tag_list.present? && state == :active ? filter_count : active_count
    end

    def inactive_contributors_count
      tag_list.present? && state == :inactive ? filter_count : inactive_count
    end

    def unsubscribed_contributors_count
      tag_list.present? && state == :unsubscribed ? filter_count : unsubscribed_count
    end
  end
end
