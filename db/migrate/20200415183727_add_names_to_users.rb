# frozen_string_literal: true

class AddNamesToUsers < ActiveRecord::Migration[6.0]
  def change
    change_table(:users, bulk: true) do |t|
      t.column :username, :string
      t.column :first_name, :string
      t.column :last_name, :string
    end
  end
end
