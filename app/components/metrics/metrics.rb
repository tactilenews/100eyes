# frozen_string_literal: true

module Metrics
  class Metrics < ApplicationComponent
    def initialize(metrics:, **)
      super

      @metrics = metrics
    end

    def call
      return render CardMetrics::CardMetrics.new(metrics: metrics) if styles.include?(:cards)

      render InlineMetrics::InlineMetrics.new(metrics: metrics)
    end

    private

    attr_reader :metrics
  end
end
