# frozen_string_literal: true

class AddTelegramMediaGroupIdToReplies < ActiveRecord::Migration[6.0]
  def change
    add_column :replies, :telegram_media_group_id, :string
    add_index :replies, :telegram_media_group_id, unique: true
  end
end
