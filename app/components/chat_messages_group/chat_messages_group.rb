# frozen_string_literal: true

module ChatMessagesGroup
  class ChatMessagesGroup < ApplicationComponent
    def initialize(organization:, contributor:, messages:, request:, **)
      super

      @organization = organization
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

    attr_reader :organization, :contributor, :messages
  end
end
