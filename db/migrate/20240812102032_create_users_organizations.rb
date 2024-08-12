# frozen_string_literal: true

class CreateUsersOrganizations < ActiveRecord::Migration[6.1]
  def change
    create_table :users_organizations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
  end
end
