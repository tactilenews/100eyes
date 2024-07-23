# frozen_string_literal: true

module SearchResult
  class SearchResult < ApplicationComponent
    def initialize(organization:, result: nil)
      super

      @organization = organization
      @result = result
    end

    private

    attr_reader :organization, :result

    def type
      result.model_name.name
    end
  end
end
