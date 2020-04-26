# frozen_string_literal: true

module Message
  class Message < ViewComponent::Base
    include ComponentHelper

    def initialize(message:)
      @message = message
    end

    private

    attr_reader :message
  end
end
