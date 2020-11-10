# frozen_string_literal: true

module ChatMessagesGroup
  class ChatMessagesGroup < ApplicationComponent
    def initialize(contributor:, messages:, **)
      super

      @contributor = contributor
      @messages = messages
    end

    private

    def conversation_link
      messages.first.conversation_link
    end

    attr_reader :contributor, :messages
  end
end
