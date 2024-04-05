# frozen_string_literal: true

module RequestNotification
  class RequestNotification < ApplicationComponent
    def initialize(request_for_info:, **)
      super

      @request_for_info = request_for_info
    end

    private

    attr_reader :request_for_info

    def last_updated_at
      Time.zone.now.iso8601
    end
  end
end
