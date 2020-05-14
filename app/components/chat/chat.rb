# frozen_string_literal: true

module Chat
  class Chat < ViewComponent::Base
    include ComponentHelper

    def initialize(messages:)
      @messages = messages
    end

    private

    attr_reader :messages
  end
end
