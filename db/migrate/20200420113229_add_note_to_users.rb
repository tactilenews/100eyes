# frozen_string_literal: true

class AddNoteToContributors < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :note, :string
  end
end
