# frozen_string_literal: true

module Pagination
  class Pagination < ApplicationComponent
    def initialize(current_page:, remote:, pages:, path:)
      super

      @current_page = current_page
      @remote = remote
      @pages = pages
      @path = path
    end

    attr_reader :current_page, :remote, :pages, :path

    def path_to(page:)
      "#{path}/page/#{page}"
    end
  end
end
