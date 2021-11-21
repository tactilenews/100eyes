# frozen_string_literal: true

module Stack
  class Component < ApplicationComponent
    def initialize(space: nil, **)
      super

      @styles = [space] if space
    end

    def call
      tag.div(content, **attrs)
    end
  end
end
