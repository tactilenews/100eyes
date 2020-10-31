# frozen_string_literal: true

class AddUniqueIndicesToContributor < ActiveRecord::Migration[6.0]
  def change
    add_index :users, :email, unique: true
    add_index :users, :chat_id, unique: true
  end
end
