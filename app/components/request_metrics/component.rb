# frozen_string_literal: true

module RequestMetrics
  class Component < ApplicationComponent
    def initialize(request:, **)
      super

      @request = request
    end

    def call
      component('metrics', metrics: metrics, styles: styles)
    end

    private

    attr_reader :request

    def metrics
      stats = request.stats
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
