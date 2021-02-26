# frozen_string_literal: true

module PlaintextMessage
  class PlaintextMessage < ApplicationComponent
    def initialize(message: nil, **)
      super

      @message = message
    end

    private

    attr_reader :message

    def empty?
      message_content.empty?
    end

    def rendered
      simple_format(h(message_content))
    end

    def message_content
      (message || content || '').strip
    end
  end
end
