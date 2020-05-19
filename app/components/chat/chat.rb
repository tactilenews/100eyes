# frozen_string_literal: true

module Chat
  class Chat < ApplicationComponent
    def initialize(messages:, user:)
      @messages = messages
      @user = user
    end

    private

    attr_reader :messages, :user
  end
end
