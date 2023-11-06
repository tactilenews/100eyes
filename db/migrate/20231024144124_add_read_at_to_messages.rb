# frozen_string_literal: true

class AddReadAtToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :read_at, :datetime, default: nil
  end
end
