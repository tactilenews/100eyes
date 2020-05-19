# frozen_string_literal: true

module Checkbox
  class Checkbox < ApplicationComponent
    def initialize(id: nil, value: nil, group: false, label: nil, stimulus_target: nil)
      @id = id
      @value = value
      @group = group
      @label = label
      @stimulus_target = stimulus_target
    end

    private

    def name
      return "#{id}[]" if group
      return id
    end

    attr_reader :id, :value, :group, :label, :stimulus_target
  end
end
