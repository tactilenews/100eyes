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

    def active_request?
      user.active_request == request
    end
  end
end
