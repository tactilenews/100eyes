# frozen_string_literal: true

module CardMetrics
  class CardMetrics < ApplicationComponent
    def initialize(metrics:, **)
      super

      @metrics = metrics
    end

    private

    attr_reader :metrics
  end
end
