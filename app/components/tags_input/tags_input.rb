# frozen_string_literal: true

module TagsInput
  class TagsInput < ApplicationComponent
    def initialize(value: [], available_tags: [], allow_new: true, **kwargs)
      super

      @value = value
      @allow_new = allow_new
      @props = kwargs
    end

    private

    attr_reader :props, :allow_new

    def value
      @value.join(',')
    end

    def available_tags
      User.all_tags_with_count
    end
  end
end
