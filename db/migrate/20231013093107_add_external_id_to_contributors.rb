# frozen_string_literal: true

class AddExternalIdToContributors < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :external_id, :string, unique: true
  end
end
