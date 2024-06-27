# frozen_string_literal: true

# There is an issue to remove this as it is no longer used
# after the conversations feature was released.
module Chat
  class Chat < ApplicationComponent
    def initialize(messages:, contributor:, request:)
      super

      @messages = messages
      @contributor = contributor
      @request = request
    end

    private

    attr_reader :messages, :contributor, :request

    def active_request
      contributor.active_request
    end

    def active_request?
      active_request == request
    end

    def active_conversation_path
      contributor_request_path(id: active_request.id, contributor_id: contributor.id)
    end
  end
end
