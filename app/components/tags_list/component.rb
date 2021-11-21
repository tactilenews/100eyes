# frozen_string_literal: true

module TagsList
  class Component < ApplicationComponent
    def initialize(tags:, **)
      super
      @tags = tags
    end

    private

    attr_reader :tags
  end
end
