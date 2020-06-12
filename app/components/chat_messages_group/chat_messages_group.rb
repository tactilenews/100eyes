# frozen_string_literal: true

module ChatMessagesGroup
  class ChatMessagesGroup < ApplicationComponent
    def initialize(user:, messages:, **)
      super

      @user = user
      @messages = messages
    end

    private

    def conversation_link
      messages.first.conversation_link
    end

    attr_reader :user, :messages
  end
end
