# frozen_string_literal: true

module RequestRow
  class RequestRow < ApplicationComponent
    def initialize(request:)
      @request = request
    end

    private

    attr_reader :request
  end
end
