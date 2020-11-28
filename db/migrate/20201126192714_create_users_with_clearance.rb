# frozen_string_literal: true

class CreateUsersWithClearance < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.timestamps null: false
      t.string :email, null: false
      t.string :encrypted_password, limit: 128, null: false
      t.string :confirmation_token, limit: 128
      t.datetime :confirmed_at
      t.string :remember_token, limit: 128, null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :remember_token
    add_index :users, :confirmation_token, unique: true
  end
end
