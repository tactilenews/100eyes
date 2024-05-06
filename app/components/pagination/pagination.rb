# frozen_string_literal: true

module Pagination
  class Pagination < ApplicationComponent
    def initialize(current_page:, remote:, pages:, path:, query: {})
      super

      @current_page = current_page
      @remote = remote
      @pages = pages
      @path = path
      @query = query
    end

    attr_reader :current_page, :remote, :pages, :path, :query

    def path_to(page:)
      "#{path}/page/#{page}?#{query.select { |_key, value| value }.to_query}"
    end
  end
end
