# frozen_string_literal: true

module PlaintextMessage
  class PlaintextMessage < ApplicationComponent
    def initialize(message:, **)
      super

      @message = message
    end

    def call
      content_tag(:div, @message, class: class_names)
    end
  end
end
