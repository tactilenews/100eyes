# frozen_string_literal: true

module Checkbox
  class Checkbox < ApplicationComponent
    def initialize(id: nil, checked: false, group: false, label: nil, required: false, **)
      super
      @id = id
      @checked = checked
      @group = group
      @label = label
      @required = required
    end

    private

    def name
      return "#{id}[]" if group

      id
    end

    attr_reader :id, :checked, :group, :label, :required
  end
end
