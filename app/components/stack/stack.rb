# frozen_string_literal: true

module Stack
  class Stack < ApplicationComponent
    def initialize(space: nil, **)
      super

      @styles = [space] if space
    end

    def call
      tag.div(content, **attrs)
    end

    private

    attr_reader :content
  end
end
