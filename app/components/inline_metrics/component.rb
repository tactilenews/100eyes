# frozen_string_literal: true

module InlineMetrics
  class Component < ApplicationComponent
    def initialize(metrics:, **)
      super

      @metrics = metrics
    end

    private

    attr_reader :metrics
  end
end
