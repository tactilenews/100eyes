# frozen_string_literal: true

module Metrics
  class Component < ApplicationComponent
    def initialize(metrics:, **)
      super

      @metrics = metrics
    end

    def call
      return component('card_metrics', metrics: metrics) if styles.include?(:cards)

      component('inline_metrics', metrics: metrics)
    end

    private

    attr_reader :metrics
  end
end
