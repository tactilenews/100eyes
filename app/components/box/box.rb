# frozen_string_literal: true

module Box
  class Box < ApplicationComponent
    def call
      tag.div(content, **attrs)
    end
  end
end
