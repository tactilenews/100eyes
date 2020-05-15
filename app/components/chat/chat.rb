# frozen_string_literal: true

module Chat
  class Chat < ViewComponent::Base
    include ComponentHelper

    def initialize(messages:, user:)
      @messages = messages
      @user = user
    end

    private

    attr_reader :messages, :user
  end
end
