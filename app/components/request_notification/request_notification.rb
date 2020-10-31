# frozen_string_literal: true

module RequestNotification
  class RequestNotification < ApplicationComponent
    def initialize(request:, **)
      super

      @request = request
    end

    private

    attr_reader :request

    def last_updated_at
      Time.zone.now.iso8601
    end
  end
end
