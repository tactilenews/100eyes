# frozen_string_literal: true

module RequestsFeed
  class RequestsFeed < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor

    def replies
      @replies ||= contributor.recent_replies
    end
  end
end
