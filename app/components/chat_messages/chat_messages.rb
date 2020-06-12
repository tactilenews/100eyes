# frozen_string_literal: true

module ChatMessages
  class ChatMessages < ApplicationComponent
    def initialize(messages:, **)
      @messages = messages
    end

    private

    attr_reader :messages
  end
end
