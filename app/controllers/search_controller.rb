# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    @results = []
    query = params[:q]
    @results = PgSearch.multisearch(query) if query
  end
end
