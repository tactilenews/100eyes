# frozen_string_literal: true

module TagsInput
  class TagsInput < ApplicationComponent
    def initialize(value: [], **kwargs)
      super

      @value = value
      @props = kwargs
    end

    private

    attr_reader :props

    def value
      @value.join(',')
    end
  end
end
