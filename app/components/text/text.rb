# frozen_string_literal: true

module Text
  class Text < ApplicationComponent
    def call
      tag.span(content, class: class_attr)
    end
  end
end
