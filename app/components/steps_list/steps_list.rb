# frozen_string_literal: true

module StepsList
  class StepsList < ApplicationComponent
    def initialize(steps:, **)
      @steps = steps
    end

    private

    attr_reader :steps
  end
end
