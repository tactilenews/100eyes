# frozen_string_literal: true

module ChatMessage
  class ChatMessage < ApplicationComponent
    def initialize(message:)
      @message = message
      @user = message.user if message.respond_to?(:user)
    end

    private

    def photos
      # TODO: refactor and remove guard clause
      return message.photos if message.is_a? Message

      []
    end

    attr_reader :message, :user
  end
end
