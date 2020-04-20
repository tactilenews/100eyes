# frozen_string_literal: true

module Button
  class Button < ViewComponent::Base
    def initialize(label: nil, style: 'primary', type: nil, link: nil)
      @label = label
      @style = style
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

    def class_names
      ['c-button', "c-button--#{style}"]
    end

    def content
      label || @content
    end

    attr_reader :label, :style, :type, :link
  end
end
