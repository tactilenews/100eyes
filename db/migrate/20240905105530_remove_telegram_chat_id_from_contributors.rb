# frozen_string_literal: true

class RemoveTelegramChatIdFromContributors < ActiveRecord::Migration[6.1]
  def change
    remove_column :contributors, :telegram_chat_id, :bigint
  end
end
