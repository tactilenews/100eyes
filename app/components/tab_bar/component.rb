# frozen_string_literal: true

module TabBar
  class Component < ApplicationComponent
    def initialize(items:, **)
      super

      @items = items
    end

    private

    attr_reader :items
  end
end
