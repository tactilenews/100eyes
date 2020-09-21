# frozen_string_literal: true

module TagsInput
  class TagsInput < ApplicationComponent
    def initialize(id: nil, value: [], **)
      super

      @id = id
      @value = value
    end

    private

    attr_reader :id

    def value
      @value.join(',')
    end
  end
end
