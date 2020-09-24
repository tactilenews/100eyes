# frozen_string_literal: true

class RemoveStreetFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :street, :string
  end
end
