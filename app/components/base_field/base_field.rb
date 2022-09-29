# frozen_string_literal: true

module BaseField
  class BaseField < ApplicationComponent
    def initialize(id:, label:, help: nil, help_md: nil, errors: [], hide_label: false, **)
      super

      @id = id
      @label = label
      @help = help
      @help_md = help_md
      @errors = errors
      @hide_label = hide_label
    end

    private

    attr_reader :id, :label, :help, :help_md, :errors, :hide_label
  end
end
