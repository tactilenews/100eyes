# frozen_string_literal: true

module CommunityMetrics
  class CommunityMetrics < ApplicationComponent
    def initialize(active_contributors_count:, requests_count:, replies_count:, engagement_metric:, **)
      super

      @active_contributors_count = active_contributors_count
      @requests_count = requests_count
      @replies_count = replies_count
      @engagement_metric = engagement_metric
    end

    def call
      render CardMetrics::CardMetrics.new(metrics: metrics)
    end

    private

    attr_reader :active_contributors_count, :requests_count, :replies_count, :engagement_metric

    def metrics
      [
        {
          value: active_contributors_count,
          label: t('.contributors', count: active_contributors_count),
          custom_icon: 'bee-turq'
        },
        {
          value: requests_count,
          label: t('.requests', count: requests_count),
          custom_icon: 'flyer-turq'
        },
        {
          value: replies_count,
          label: t('.replies', count: replies_count),
          custom_icon: 'letter_turq'
        },
        {
          value: number_to_percentage(engagement_metric, precision: 0, locale: :en),
          label: t('.engagement_metric'),
          custom_icon: 'percent_turq'
        }
      ]
    end
  end
end
