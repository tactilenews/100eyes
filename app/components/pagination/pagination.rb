# frozen_string_literal: true

module Pagination
  class Pagination < ApplicationComponent
    def initialize(current_page:, remote:, page_links:)
      super

      @current_page = current_page
      @remote = remote
      @page_links = page_links
      # binding.pry
    end

    attr_reader :current_page, :remote, :page_links
  end
end
