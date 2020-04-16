# frozen_string_literal: true

module Tile
  class Tile < ApplicationComponent
    def initialize(url:, icon:, action:, subject:)
      @url = url
      @icon = icon
      @action = action
      @subject = subject
    end

    private

    attr_reader :url, :icon, :action, :subject

    def icon_url
      "/icons.svg##{icon}"
    end
  end
end
