# frozen_string_literal: true

module TagsInput
  class TagsInput < ApplicationComponent
    def initialize(value: [], options: [], **kwargs)
      super

      @value = value
      @options = options
      @props = kwargs
    end

    private

    attr_reader :props

    def value
      @value.join(',')
    end

    def options
      @options.to_json
    end
  end
end
