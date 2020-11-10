# frozen_string_literal: true

class RenameUsersToContributors < ActiveRecord::Migration[6.0]
  def change
    rename_table :users, :contributors
  end
end
