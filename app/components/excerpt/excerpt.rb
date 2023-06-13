# frozen_string_literal: true

module Excerpt
  class Excerpt < ApplicationComponent
    def initialize(title:, text:, link:, date:, sender: nil, **)
      super

      @sender = sender
      @title = title
      @text = text
      @link = link
      @date = date
    end

    private

    attr_reader :sender, :title, :text, :link, :date
  end
end
