# frozen_string_literal: true

module RequestRow
  class RequestRow < ApplicationComponent
    def initialize(request:, **)
      super
      @request = request
    end

    private

    attr_reader :request

    def request_metrics
      [
        {
          value: 0,
          total: 0,
          label: I18n.t('components.request_metrics.contributors', count: 0),
          icon: 'single-03'
        },
        {
          value: 0,
          label: I18n.t('components.request_metrics.replies', count: 0),
          icon: 'a-chat'
        },
        {
          value: 0,
          label: I18n.t('components.request_metrics.photos', count: 0),
          icon: 'camera'
        }
      ]
    end
  end
end
