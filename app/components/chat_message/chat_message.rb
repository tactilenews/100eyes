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

    def warnings
      warnings = []
      warnings << I18n.t('components.chat_message.contains_unknown_content') if message.unknown_content
      warnings << I18n.t('components.chat_message.blocked_by_user') if message.blocked
      warnings
    end

    attr_reader :message
  end
end
