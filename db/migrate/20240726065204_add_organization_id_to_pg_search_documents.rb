# frozen_string_literal: true

class AddOrganizationIdToPgSearchDocuments < ActiveRecord::Migration[6.1]
  def change
    add_reference :pg_search_documents, :organization, foreign_key: true
  end
end
