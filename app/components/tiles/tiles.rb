# frozen_string_literal: true

module Tiles
  class Tiles < ApplicationComponent
    def initialize(*); end

    def call
      content_tag(:div, @content, class: 'Tiles')
    end
  end
end
