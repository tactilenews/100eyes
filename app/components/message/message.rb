# frozen_string_literal: true

module Message
  class Message < ApplicationComponent
    def initialize(message:)
      @message = message
      @user = message.user if message.respond_to?(:user)
    end

    private

    def photos
      return message.photos if message.is_a? Reply

      []
    end

    attr_reader :message, :user
  end
end
