# frozen_string_literal: true

module Metric
  class Metric < ApplicationComponent
    def initialize(value:, label:, icon: nil, total: nil, custom_icon: nil, **)
      super

      @value = value
      @total = total
      @label = label
      @icon = icon
      @custom_icon = custom_icon
    end

    private

    attr_reader :value, :total, :label, :icon, :custom_icon

    def formatted
      return value if total.nil?

      "#{value}/#{total}"
    end
  end
end
