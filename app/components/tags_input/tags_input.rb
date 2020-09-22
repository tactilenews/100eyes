# frozen_string_literal: true

module TagsInput
  class TagsInput < ApplicationComponent
    def initialize(value: [], options: [], allow_new: true, **kwargs)
      super

      @value = value
      @options = options
      @allow_new = allow_new
      @props = kwargs
    end

    private

    attr_reader :props, :allow_new

    def value
      @value.join(',')
    end

    def options
      @options.to_json
    end
  end
end
