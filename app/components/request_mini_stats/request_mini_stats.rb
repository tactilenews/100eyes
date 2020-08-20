# frozen_string_literal: true

module RequestMiniStats
  class RequestMiniStats < ApplicationComponent
    def initialize(request:, **)
      super

      @request = request
    end
  end
end
