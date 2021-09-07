# frozen_string_literal: true

module Icon
  class Icon < ApplicationComponent
    def initialize(icon:, title: nil, size: 24, label: nil, **)
      super

      @icon = icon
      @title = title
      @size = size
      @label = label
    end

    private

    attr_reader :icon, :title, :size, :label

    def default_attributes
      return { 'aria-hidden': 'true' } unless label

      { 'aria-label': label }
    end

    def url
      "/icons.svg#icon-#{icon}-glyph-#{size}"
    end
  end
end
