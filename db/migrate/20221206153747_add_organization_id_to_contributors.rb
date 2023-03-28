# frozen_string_literal: true

class AddOrganizationIdToContributors < ActiveRecord::Migration[6.1]
  def change
    add_reference :contributors, :organization, foreign_key: true
  end
end
