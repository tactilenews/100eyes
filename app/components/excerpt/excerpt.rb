# frozen_string_literal: true

module Excerpt
  class Excerpt < ApplicationComponent
    def initialize(organization:, title:, text:, link:, date:, sender: nil, **)
      super

      @organization = organization
      @sender = sender
      @title = title
      @text = text
      @link = link
      @date = date
    end

    private

    attr_reader :organization, :sender, :title, :text, :link, :date
  end
end
