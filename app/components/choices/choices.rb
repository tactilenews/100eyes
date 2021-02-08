# frozen_string_literal: true

module Choices
  class Choices < ApplicationComponent
    def initialize(id:, choices: [], value: nil, stimulus_controller: nil, stimulus_target: nil, **)
      super

      @id = id
      @choices = choices
      @value = value
      @stimulus_controller = stimulus_controller
      @stimulus_target = stimulus_target
    end

    private

    attr_reader :id, :choices, :value, :stimulus_target, :stimulus_controller
  end
end
