# frozen_string_literal: true

class CreateContributors < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :email
      t.integer :chat_id
      t.timestamps
    end
  end
end
