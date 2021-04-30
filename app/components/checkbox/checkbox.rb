# frozen_string_literal: true

module Checkbox
  class Checkbox < ApplicationComponent
    def initialize(id: nil, value: nil, group: false, label: nil, required: false, **)
      super
      @id = id
      @value = value
      @group = group
      @label = label
      @required = required
    end

    private

    def name
      return "#{id}[]" if group

      id
    end

    attr_reader :id, :value, :group, :label, :required
  end
end
