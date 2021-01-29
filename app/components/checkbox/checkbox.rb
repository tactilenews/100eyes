# frozen_string_literal: true

module Checkbox
  class Checkbox < ApplicationComponent
    def initialize(id: nil, value: nil, group: false, label: nil, **)
      super
      @id = id
      @value = value
      @group = group
      @label = label
    end

    private

    def name
      return "#{id}[]" if group

      id
    end

    attr_reader :id, :value, :group, :label
  end
end
