# frozen_string_literal: true

module Placeholder
  class Placeholder < ApplicationComponent
    def call
      content_tag(:span, @content, class: class_names)
    end
  end
end
