# frozen_string_literal: true

module Checkbox
  class Checkbox < ApplicationComponent
    def initialize(id: nil, label: nil, stimulus_target: nil)
      @id = id
      @label = label
      @stimulus_target = stimulus_target
    end

    private

    attr_reader :id, :label, :stimulus_target
  end
end
