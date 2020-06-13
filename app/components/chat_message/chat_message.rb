# frozen_string_literal: true

module ChatMessage
  class ChatMessage < ApplicationComponent
    def initialize(message:, **)
      super
      @message = message
    end

    private

    def id
      "message-#{message.id}"
    end

    def photos
      message.photos
    end

    def unknown_content?
      message.unknown_content?
    end

    attr_reader :message
  end
end
