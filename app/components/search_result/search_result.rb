# frozen_string_literal: true

module SearchResult
  class SearchResult < ApplicationComponent
    def initialize(result: nil)
      super

      @result = result
    end

    private

    attr_reader :result

    def type
      result.model_name.name
    end
  end
end
