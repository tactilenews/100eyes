# frozen_string_literal: true

module PlaintextMessage
  class PlaintextMessage < ApplicationComponent
    def initialize(message: nil, **)
      super

      @message = message
    end

    def call
      content_tag(:div, content, class: class_names)
    end

    private

    attr_reader :message

    def content
      message || @content
    end
  end
end
