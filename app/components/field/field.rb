# frozen_string_literal: true

module Field
  class Field < ApplicationComponent
    def initialize(label:, help: nil, **)
      super

      @label = label
      @help = help
    end

    private

    attr_reader :content, :label, :help
  end
end
