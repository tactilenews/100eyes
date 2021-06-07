# frozen_string_literal: true

module IconList
  class IconList < ApplicationComponent
    def initialize(elements:, **)
      super

      @elements = elements
    end

    private

    attr_reader :elements
  end
end
