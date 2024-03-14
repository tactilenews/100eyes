# frozen_string_literal: true

class AddReceivedAtToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :received_at, :datetime, default: nil
  end
end
