# frozen_string_literal: true

module Metric
  class Metric < ApplicationComponent
    def initialize(value:, total: nil, label:, icon:, **)
      super

      @value = value
      @total = total
      @label = label
      @icon = icon
    end

    private

    attr_reader :value, :total, :label, :icon

    def formatted
      return value if total.nil?

      "#{value}/#{total}"
    end
  end
end
