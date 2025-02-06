# frozen_string_literal: true

module RequestsFeed
  class RequestsFeed < ApplicationComponent
    def initialize(organization:, contributor:, **)
      super

      @organization = organization
      @contributor = contributor
    end

    private

    attr_reader :organization, :contributor

    def replies
      @replies ||= most_recent_reply_to_each_request
    end

    def most_recent_reply_to_each_request
      result = contributor.replies.with_request_attached.includes(:recipient, :request).reorder(created_at: :desc)
      result = result.group_by(&:request).values # array or groups
      result = result.map(&:first) # choose most recent message per group
      result.sort_by(&:created_at).reverse # ensure descending order
    end
  end
end
