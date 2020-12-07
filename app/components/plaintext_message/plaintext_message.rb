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
      content.empty?
    end

    def rendered
      simple_format(content)
    end

    def content
      (message || @content || '').strip
    end
  end
end
