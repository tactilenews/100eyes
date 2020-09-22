# frozen_string_literal: true

module RequestNotification
  class RequestNotification < ApplicationComponent
    def initialize(request:, **)
      @request = request
    end

    attr_reader :request

    private

    def last_updated_at
      Time.zone.now.iso8601
    end
  end
end
