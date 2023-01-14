# frozen_string_literal: true

module Pagination
  class Pagination < ApplicationComponent
    def initialize(current_page:, remote:, pages:)
      super

      @current_page = current_page
      @remote = remote
      @pages = pages
    end

    attr_reader :current_page, :remote, :pages
  end
end
