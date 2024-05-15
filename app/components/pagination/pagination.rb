# frozen_string_literal: true

module Pagination
  class Pagination < ApplicationComponent
    def initialize(current_page:, remote:, pages:, path:, query: nil)
      super

      @current_page = current_page
      @remote = remote
      @pages = pages
      @path = path
      @query = query
    end

    attr_reader :current_page, :remote, :pages, :path, :query

    def path_to(page:)
      path_without_query = "#{path}/page/#{page}"
      return path_without_query unless query

      "#{path_without_query}?#{query.select { |_key, value| value }.to_query}"
    end
  end
end
