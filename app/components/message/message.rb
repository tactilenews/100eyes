# frozen_string_literal: true

module Message
  class Message < ViewComponent::Base
    include ComponentHelper

    def initialize(message:)
      @message = message
      @user = message.user if message.respond_to?(:user)
    end

    private

    attr_reader :message, :user
  end
end
