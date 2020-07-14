# frozen_string_literal: true

module Wrapper
  class Wrapper < ApplicationComponent
    def initialize(**)
      super
    end

    def call
      content_tag(:div, @content, class: class_attr)
    end
  end
end
