# frozen_string_literal: true

module TwoColumnLayout
  class TwoColumnLayout < ApplicationComponent
    renders_one :sidebar

    def initialize(id:, **)
      super

      @id = id
    end

    private

    attr_reader :id
  end
end
