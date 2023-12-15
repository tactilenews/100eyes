# frozen_string_literal: true

module DestroyPlannedRequestModal
  class DestroyPlannedRequestModal < ApplicationComponent
    def initialize(planned_request:, **)
      super

      @planned_request = planned_request
    end

    attr_reader :planned_request
  end
end
