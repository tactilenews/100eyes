# frozen_string_literal: true

module RequestForm
  class RequestForm < ApplicationComponent
    def initialize(request:)
      super

      @request = request
    end

    private

    attr_reader :request

    def available_tags
      Contributor.all_tags_with_count.to_json
    end

    def schedule_send_for_or_default
      request.schedule_send_for.present? ? request.schedule_send_for.strftime('%Y-%m-%dT%H:%M') : Time.current.strftime('%Y-%m-%dT%H:%M')
    end
  end
end
