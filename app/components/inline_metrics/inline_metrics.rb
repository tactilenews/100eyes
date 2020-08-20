# frozen_string_literal: true

module InlineMetrics
  class InlineMetrics < ApplicationComponent
    def initialize(metrics:, **)
      super

      @metrics = metrics
    end

    private

    attr_reader :metrics
  end
end
