# frozen_string_literal: true

module Chat
  class Chat < ApplicationComponent
    def initialize(messages:, user:, request:)
      @messages = messages
      @user = user
      @request = request
    end

    private

    attr_reader :messages, :user, :request

    def active_request
      user.active_request
    end

    def active_request?
      active_request == request
    end

    def active_conversation_path
      user_request_path(id: active_request.id, user_id: user.id)
    end
  end
end
