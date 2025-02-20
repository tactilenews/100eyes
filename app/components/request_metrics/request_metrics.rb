# frozen_string_literal: true

module RequestMetrics
  class RequestMetrics < ApplicationComponent
    def initialize(request_for_info:, **)
      super

      @request_for_info = request_for_info
    end

    def call
      render Metrics::Metrics.new(metrics: metrics, styles: styles)
    end

    private

    attr_reader :request_for_info

    def metrics
      stats = request_for_info.stats
      [
        {
          value: stats[:counts][:contributors],
          total: stats[:counts][:recipients],
          label: I18n.t('components.request_metrics.contributors', count: stats[:counts][:contributors]),
          icon: 'single-03'
        },
        {
          value: stats[:counts][:replies],
          label: I18n.t('components.request_metrics.replies', count: stats[:counts][:replies]),
          icon: 'a-chat'
        },
        {
          value: stats[:counts][:photos],
          label: I18n.t('components.request_metrics.photos', count: stats[:counts][:photos]),
          icon: 'camera'
        }
      ]
    end
  end
end
