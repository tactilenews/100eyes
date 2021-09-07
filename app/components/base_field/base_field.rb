# frozen_string_literal: true

module BaseField
  class BaseField < ApplicationComponent
    def initialize(id:, label:, help: nil, errors: [], **)
      super

      @id = id
      @label = label
      @help = help
      @errors = errors
    end

    private

    attr_reader :id, :label, :help, :errors
  end
end
