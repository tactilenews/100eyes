# frozen_string_literal: true

module ContributorMetrics
  class ContributorMetrics < ApplicationComponent
    def initialize(contributor_for_info:, **)
      super

      @contributor_for_info = contributor_for_info
    end

    def call
      render Metrics::Metrics.new(metrics: metrics, styles: styles)
    end

    private

    attr_reader :contributor_for_info

    def metrics
      stats = contributor_for_info.stats
      [
        {
          value: stats[:counts][:replied_to_requests],
          total: stats[:counts][:received_requests],
          label: I18n.t('components.contributor_metrics.requests', count: stats[:counts][:replied_to_requests]),
          icon: 'a-chat'
        },
        {
          value: stats[:counts][:replies],
          label: I18n.t('components.contributor_metrics.replies', count: stats[:counts][:replies]),
          icon: 'a-chat'
        }
      ]
    end
  end
end
