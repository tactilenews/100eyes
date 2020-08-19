# frozen_string_literal: true

module RequestMetrics
  class RequestMetrics < ApplicationComponent
    def initialize(request:, **)
      super

      @request = request
    end
  end
end
