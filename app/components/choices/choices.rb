# frozen_string_literal: true

module Choices
  class Choices < ApplicationComponent
    def initialize(choices: [], stimulus_controller: nil, stimulus_target: nil, **)
      super

      @choices = choices
      @stimulus_controller = stimulus_controller
      @stimulus_target = stimulus_target
    end

    private

    attr_reader :choices, :stimulus_target, :stimulus_controller
  end
end
