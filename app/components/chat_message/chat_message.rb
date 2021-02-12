# frozen_string_literal: true

module ChatMessage
  class ChatMessage < ApplicationComponent
    def initialize(message:, hide_actions: false, **)
      super

      @message = message
      @hide_actions = hide_actions
    end

    private

    attr_reader :message, :hide_actions

    def styles
      return super unless @message.highlighted?

      super + [:highlighted]
    end

    def id
      "message-#{message.id}"
    end

    def audio
      message.file
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

    def move_link
      message_request_path(message)
    end
  end
end
