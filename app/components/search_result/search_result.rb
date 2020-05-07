# frozen_string_literal: true

module SearchResult
  class SearchResult < ApplicationComponent
    def initialize(result: nil)
      @result = result
    end

    private

    attr_reader :result

    def link
      return helpers.user_request_path(user_id: result.user_id, id: result.request_id) if result.respond_to?(:user_id)

      helpers.user_path(id: result.id)
    end

    def label
      return result.name if result.respond_to?(:name)

      result.text
    end
  end
end
