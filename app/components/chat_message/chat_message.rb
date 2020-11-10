# frozen_string_literal: true

module ChatMessage
  class ChatMessage < ApplicationComponent
    def initialize(message:, **)
      super

      @message = message
    end

    private

    def styles
      return super unless @message.highlighted?

      super + [:highlighted]
    end

    def id
      "message-#{message.id}"
    end

    def voice
      message.voice
    end

    def photos
      message.photos
    end

    def warnings
      warnings = []
      warnings << I18n.t('components.chat_message.contains_unknown_content') if message.unknown_content
      warnings << I18n.t('components.chat_message.blocked_by_contributor') if message.blocked
      warnings
    end

    attr_reader :message
  end
end
