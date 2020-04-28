# frozen_string_literal: true

module PageHeader
  class PageHeader < ApplicationComponent
    def initialize(title: nil, icon: nil)
      @title = title
      @icon = icon
    end

    private

    attr_reader :title, :icon
  end
end
