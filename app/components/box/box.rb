# frozen_string_literal: true

module Box
  class Box < ApplicationComponent
    def initialize(**)
      super
    end

    def call
      content_tag(:div, @content, class: class_names)
    end
  end
end
