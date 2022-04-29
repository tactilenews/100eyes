# frozen_string_literal: true

module RequestForm
  class RequestForm < ApplicationComponent
    def initialize(request:)
      super

      @request = request
    end

    private

    attr_reader :request

    def available_tags
      Contributor.all_tags_with_count.to_json
    end
  end
end
