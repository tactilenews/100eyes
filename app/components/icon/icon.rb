# frozen_string_literal: true

module Icon
  class Icon < ApplicationComponent
    def initialize(icon:, title: nil, **)
      super

      @icon = icon
      @title = title
    end

    private

    attr_reader :icon, :title

    def url
      "/icons.svg#nc-icon-#{icon}-glyph-24"
    end
  end
end
