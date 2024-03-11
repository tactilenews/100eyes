# frozen_string_literal: true

module InlineMetrics
  class InlineMetrics < ApplicationComponent
    def initialize(metrics:, path: nil, **)
      super

      @metrics = metrics
      @path = path
    end

    private

    attr_reader :metrics, :path
  end
end
