# frozen_string_literal: true

module TagsInput
  class TagsInput < ApplicationComponent
    def initialize(value: [], available_tags: [], allow_new: true, **kwargs)
      super

      @value = value
      @available_tags = available_tags
      @allow_new = allow_new
      @props = kwargs
    end

    private

    attr_reader :props, :allow_new

    def value
      @value.join(',')
    end

    def available_tags
      @available_tags.map { |tag| { name: tag.name, value: tag.name, count: tag.taggings_count } }.to_json
    end
  end
end
