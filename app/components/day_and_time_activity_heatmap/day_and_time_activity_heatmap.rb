# frozen_string_literal: true

module DayAndTimeActivityHeatmap
  class DayAndTimeActivityHeatmap < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    private

    attr_reader :organization
  end
end
