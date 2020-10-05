# frozen_string_literal: true

module TagsInput
  class TagsInput < ApplicationComponent
    def initialize(value: [], available_tags: [], allow_new: true, **kwargs)
      super

      @value = value
      @allow_new = allow_new
      @available_tags = available_tags
      @props = kwargs
    end

    private

    attr_reader :props, :available_tags, :allow_new

    def value
      @value.join(',')
    end
  end
end
