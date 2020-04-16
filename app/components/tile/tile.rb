# frozen_string_literal: true

module Tile
  class Tile < ApplicationComponent
    def initialize(url:, icon:)
      @url = url
      @icon = icon
    end

    private

    attr_reader :url, :icon

    def icon_url
      "/icons.svg##{icon}"
    end
  end
end
