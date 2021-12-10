# frozen_string_literal: true

class ChangeTelegramColumnsToBigint < ActiveRecord::Migration[6.1]
  def up
    change_table :contributors, bulk: true do |t|
      t.change :telegram_id, :bigint
      t.change :telegram_chat_id, :bigint
    end
  end

  def down
    change_table :contributors, bulk: true do |t|
      t.change :telegram_id, :integer
      t.change :telegram_chat_id, :integer
    end
  end
end
