# frozen_string_literal: true

class AddBroadcastedAtToRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :requests, :broadcasted_at, :datetime, default: nil
  end
end
