# frozen_string_literal: true

module RequestsFeedItem
  class RequestsFeedItem < ApplicationComponent
    def initialize(latest_reply:, **)
      super

      @user = latest_reply.sender
      @request = latest_reply.request
      @latest_reply = latest_reply
    end

    private

    attr_reader :user, :request, :latest_reply

    def text
      # rubocop:disable Rails/OutputSafety
      I18n.t('user.has_replied_to', title: tag.strong(request.title)).html_safe
      # rubocop:enable Rails/OutputSafety
    end

    def link
      user_request_path(id: request.id, user_id: user.id)
    end
  end
end
