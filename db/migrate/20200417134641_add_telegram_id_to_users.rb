class AddTelegramIdToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :telegram_id, :integer
    add_index :users, :telegram_id, unique: true
    remove_index :users, :chat_id
  end
end
