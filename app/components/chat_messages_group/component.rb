# frozen_string_literal: true

module ChatMessagesGroup
  class Component < ApplicationComponent
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

    def conversation_link
      messages.first.conversation_link
    end

    def add_message_link
      new_message_path(contributor_id: @contributor, request_id: @request)
    end

    attr_reader :contributor, :messages
  end
end
