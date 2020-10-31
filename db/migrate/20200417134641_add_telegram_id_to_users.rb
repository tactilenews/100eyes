# frozen_string_literal: true

class AddTelegramIdToContributors < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :chat_id, :telegram_chat_id
    add_column :users, :telegram_id, :integer
    add_index :users, :telegram_id, unique: true
  end
end
