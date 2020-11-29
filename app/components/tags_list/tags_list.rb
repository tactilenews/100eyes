# frozen_string_literal: true

module TagsList
  class TagsList < ApplicationComponent
    def initialize(tags:, **)
      super
      @tags = tags
    end

    private

    attr_reader :tags
  end
end
