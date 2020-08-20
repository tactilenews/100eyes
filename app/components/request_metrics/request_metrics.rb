# frozen_string_literal: true

module RequestMetrics
  class RequestMetrics < ApplicationComponent
    def initialize(request:, **)
      super

      @request = request
    end

    def call
      render Metrics::Metrics.new(metrics: metrics, styles: styles)
    end

    private

    attr_reader :request

    def metrics
      [
        {
          value: request.stats[:counts][:users],
          label: I18n.t('components.request_metrics.users'),
          icon: 'single-03'
        },
        {
          value: request.stats[:counts][:replies],
          label: I18n.t('components.request_metrics.replies'),
          icon: 'a-chat'
        },
        {
          value: request.stats[:counts][:photos],
          label: I18n.t('components.request_metrics.photos'),
          icon: 'camera'
        }
      ]
    end
  end
end
