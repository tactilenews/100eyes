# frozen_string_literal: true

module RequestNotification
  class RequestNotification < ApplicationComponent
    def initialize(request_for_info:, organization:, **)
      super

      @request_for_info = request_for_info
      @organization = organization
    end

    private

    attr_reader :request_for_info, :organization

    def last_updated_at
      Time.zone.now.iso8601
    end
  end
end
