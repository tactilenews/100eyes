# frozen_string_literal: true

module Button
  class Button < ApplicationComponent
    def initialize(label: nil, type: nil, link: nil, **)
      super

      @styles = [:primary] if @styles.empty?

      @label = label
      @type = type
      @link = link
    end

    def call
      content_tag(tag, content, class: class_names, type: type, href: link)
    end

    private

    def tag
      return :a if link

      :button
    end

    def content
      label || @content
    end

    attr_reader :label, :type, :link
  end
end
