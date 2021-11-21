# frozen_string_literal: true

module Text
  class Component < ApplicationComponent
    def call
      tag.span(content, class: class_attr)
    end
  end
end
