# frozen_string_literal: true

module TagsInput
  class TagsInput < ApplicationComponent
    def initialize(value: [], available_tags: [], allow_new: true, **)
      super

      @value = value
      @allow_new = allow_new
      @available_tags = available_tags
    end

    private

    attr_reader :available_tags, :allow_new

    def value
      @value.join(',')
    end
  end
end
