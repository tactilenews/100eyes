# frozen_string_literal: true

module Tiles
  class Tiles < ViewComponent::Base
    def initialize(*); end

    def call
      content_tag(:div, @content, class: 'tiles')
    end
  end
end
