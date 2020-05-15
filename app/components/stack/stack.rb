# frozen_string_literal: true

module Stack
  class Stack < ApplicationComponent
    def initialize(size: nil)
      super
      @styles = [size] if size
    end

    def call
      content_tag(:div, content, class: class_names)
    end

    private

    attr_reader :content
  end
end
