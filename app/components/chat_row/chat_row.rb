# frozen_string_literal: true

module ChatRow
  class ChatRow < ApplicationComponent
    def initialize(message:, **)
      super

      @message = message
    end

    private

    attr_reader :message

    def styles
      return [:left] if message.reply?

      [:right]
    end

    def id
      "chat-row-#{message.id}"
    end
  end
end
