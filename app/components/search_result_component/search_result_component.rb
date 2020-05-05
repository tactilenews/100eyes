# frozen_string_literal: true

module SearchResultComponent
  class SearchResultComponent < ApplicationComponent
    def initialize(result: nil)
      @result = result
    end

    private

    attr_reader :result
  end
end
