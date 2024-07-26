# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    @results = []
    query = params[:q]
    return unless query

    @results = PgSearch.multisearch(query).where(organization_id: @organization.id).map(&:searchable)
  end
end
