# frozen_string_literal: true

module SearchResult
  class Component < ApplicationComponent
    def initialize(result: nil)
      super

      @result = result
    end

    private

    attr_reader :result

    def link
      helpers.contributor_request_path(contributor_id: result.contributor_id, id: result.request_id)
    end

    def type
      result.model_name.name
    end
  end
end
