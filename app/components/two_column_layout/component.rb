# frozen_string_literal: true

module TwoColumnLayout
  class Component < ApplicationComponent
    renders_one :sidebar

    def initialize(id:, **)
      super

      @id = id
    end

    private

    attr_reader :id
  end
end
