# frozen_string_literal: true

module Excerpt
  class Excerpt < ApplicationComponent
    def initialize(title:, text:, link:, date:, **)
      super

      @title = title
      @text = text
      @link = link
      @date = date
    end

    private

    attr_reader :title, :text, :link, :date
  end
end
