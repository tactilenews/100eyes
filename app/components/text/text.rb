# frozen_string_literal: true

module Text
  class Text < ApplicationComponent
    def initialize(**)
      super
    end

    def call
      content_tag(:span, @content, class: class_attr)
    end
  end
end
