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

    def css_class
      return 'Message Message-right' if user

      'Message Message-left'
    end

    def avatar_url
      return user.avatar_url if user

      nil
    end
  end
end
