# frozen_string_literal: true

module ChatRow
  class ChatRow < ViewComponent::Base
    include ComponentHelper

    def initialize(message:)
      @message = message
    end

    private

    attr_reader :message

    def css_class
      return 'ChatRow ChatRow--left' if message.respond_to? :user

      'ChatRow ChatRow--right'
    end
  end
end
