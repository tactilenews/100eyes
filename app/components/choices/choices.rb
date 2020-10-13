# frozen_string_literal: true

module Choices
  class Choices < ApplicationComponent
    def initialize(choices: [], stimulus_target: nil, **)
      super

      @choices = choices
      @stimulus_target = stimulus_target
    end

    private

    attr_reader :choices, :stimulus_target
  end
end
