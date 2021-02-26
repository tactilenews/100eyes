# frozen_string_literal: true

module Button
  class Button < ApplicationComponent
    def initialize(label: nil, link: nil, **)
      super

      @styles = [:primary] if @styles.empty?

      @label = label
      @link = link
    end

    def call
      content_tag(tag, button_content, href: link, **attrs)
    end

    private

    attr_reader :label, :type, :link

    def tag
      return :a if link

      :button
    end

    def button_content
      label || content
    end
  end
end
