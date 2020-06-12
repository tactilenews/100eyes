# frozen_string_literal: true

class AddBroadcastedToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :broadcasted, :boolean, default: false
  end
end
