# frozen_string_literal: true

class RenameRepliesToMessages < ActiveRecord::Migration[6.0]
  def change
    rename_table :replies, :messages
    rename_column :photos, :reply_id, :message_id
  end
end
