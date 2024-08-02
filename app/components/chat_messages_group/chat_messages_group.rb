# frozen_string_literal: true

module ChatMessagesGroup
  class ChatMessagesGroup < ApplicationComponent
    def initialize(contributor:, messages:, request:, **)
      super

      @contributor = contributor
      @messages = messages
      @request = request
    end

    private

    def id
      "contributor-#{@contributor.id}"
    end

    def add_message_link
      new_message_path(contributor_id: @contributor, request_id: @request)
    end

    def organization
      @request.organization
    end

    attr_reader :contributor, :messages, :request
  end
end
