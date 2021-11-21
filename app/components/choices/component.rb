# frozen_string_literal: true

module Choices
  class Component < ApplicationComponent
    def initialize(id:, choices: [], value: nil, **)
      super

      @id = id
      @choices = choices
      @value = value
    end

    private

    attr_reader :id, :choices, :value
  end
end
