# frozen_string_literal: true

class AddBlockedFlagToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :blocked, :boolean, default: false
  end
end
