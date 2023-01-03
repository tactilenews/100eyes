# frozen_string_literal: true

module RequestRow
  class RequestRow < ApplicationComponent
    def initialize(request:, **)
      super
      @request = request
    end

    private

    attr_reader :request

    def planned_request?
      request.schedule_send_for.present? && request.schedule_send_for > Time.current
    end
  end
end
