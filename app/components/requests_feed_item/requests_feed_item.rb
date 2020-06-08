# frozen_string_literal: true

module RequestsFeedItem
  class RequestsFeedItem < ApplicationComponent
    def initialize(user:, request:, **)
      super

      @user = user
      @request = request
    end

    private

    attr_reader :user, :request

    def text
      # rubocop:disable Rails/OutputSafety
      I18n.t('user.has_replied_to', title: tag.strong(request.title)).html_safe
      # rubocop:enable Rails/OutputSafety
    end

    def link
      user_request_path(id: request.id, user_id: @user.id)
    end
  end
end
