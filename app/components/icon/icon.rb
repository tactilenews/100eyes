# frozen_string_literal: true

module Icon
  class Icon < ApplicationComponent
    def initialize(icon:, title: nil, size: 24, **)
      super

      @icon = icon
      @title = title
      @size = size
    end

    private

    attr_reader :icon, :title, :size

    def url
      "/icons.svg#icon-#{icon}-glyph-#{size}"
    end
  end
end
