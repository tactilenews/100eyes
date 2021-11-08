# frozen_string_literal: true

module BaseField
  class BaseField < ApplicationComponent
    def initialize(id:, label:, help: nil, errors: [], hide_label: false, **)
      super

      @id = id
      @label = label
      @help = help
      @errors = errors
      @hide_label = hide_label
    end

    private

    attr_reader :id, :label, :help, :errors, :hide_label
  end
end
