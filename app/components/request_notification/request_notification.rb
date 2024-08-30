# frozen_string_literal: true

# TODO: https://github.com/tactilenews/100eyes/pull/1898/files#diff-03fade3e18accd28a40e50b49dd30e8f377ffb8bec7df4e170ffd0306bf44ed2

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
