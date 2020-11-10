# frozen_string_literal: true

module RequestsFeedItem
  class RequestsFeedItem < ApplicationComponent
    def initialize(latest_reply:, **)
      super

      @contributor = latest_reply.sender
      @request = latest_reply.request
      @latest_reply = latest_reply
    end

    private

    attr_reader :contributor, :request, :latest_reply

    def text
      # rubocop:disable Rails/OutputSafety
      I18n.t('contributor.has_replied_to', title: tag.strong(request.title)).html_safe
      # rubocop:enable Rails/OutputSafety
    end

    def link
      contributor_request_path(id: request.id, contributor_id: contributor.id)
    end
  end
end
