# frozen_string_literal: true

module ChatMessage
  class ChatMessage < ApplicationComponent
    def initialize(message:)
      @message = message
      @user = message.user if message.respond_to?(:user)
    end

    private

    def photos
      message.photos
    end

    attr_reader :message, :user
  end
end
