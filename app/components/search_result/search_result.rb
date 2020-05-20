# frozen_string_literal: true

module SearchResult
  class SearchResult < ApplicationComponent
    def initialize(result: nil)
      @result = result
    end

    private

    attr_reader :result

    def link
      helpers.user_request_path(user_id: result.user_id, id: result.request_id)
    end

    def type
      return :request if result.respond_to?(:user_id)

      :user
    end
  end
end
