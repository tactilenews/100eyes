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
      @replies ||= contributor.most_recent_replies_to_some_request
    end
  end
end
