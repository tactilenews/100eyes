# frozen_string_literal: true

class AddDeactivatedAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :deactivated_at, :datetime, default: nil
  end
end
