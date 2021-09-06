# frozen_string_literal: true

module TabBar
  class TabBar < ApplicationComponent
    def initialize(items:, **)
      super

      @items = items
    end

    private

    attr_reader :items
  end
end
