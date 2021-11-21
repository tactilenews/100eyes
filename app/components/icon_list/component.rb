# frozen_string_literal: true

module IconList
  class Component < ApplicationComponent
    def initialize(elements:, **)
      super

      @elements = elements
    end

    private

    attr_reader :elements
  end
end
