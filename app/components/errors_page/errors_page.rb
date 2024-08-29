# frozen_string_literal: true

module ErrorsPage
  class ErrorsPage < ApplicationComponent
    def initialize(header:, text:)
      super

      @header = header
      @text = text
    end

    attr_reader :header, :text
  end
end
