# frozen_string_literal: true

module CommunityMetrics
  class CommunityMetrics < ApplicationComponent
    def initialize(active_contributors_count:, requests_count:, replies_count:, **)
      super

      @active_contributors_count = active_contributors_count
      @requests_count = requests_count
      @replies_count = replies_count
    end

    def call
      render Metrics::Metrics.new(metrics: metrics, styles: styles)
    end

    private

    attr_reader :active_contributors_count, :requests_count, :replies_count

    def metrics
      [
        {
          value: active_contributors_count,
          label: I18n.t('components.community_metrics.contributors', count: active_contributors_count),
          icon: 'single-03'
        },
        {
          value: requests_count,
          label: I18n.t('components.community_metrics.requests', count: requests_count),
          icon: 'user-connection'
        },
        {
          value: replies_count,
          label: I18n.t('components.community_metrics.replies', count: replies_count),
          icon: 'a-chat'
        }
      ]
    end
  end
end
