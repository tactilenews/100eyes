# frozen_string_literal: true

module StepsList
  class StepsList < ApplicationComponent
    def initialize(steps:, **)
      super

      @steps = steps
    end

    private

    attr_reader :steps
  end
end
