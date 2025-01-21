# frozen_string_literal: true

class ChangeReceivedAtToDeliverAtOnMessages < ActiveRecord::Migration[6.1]
  def change
    rename_column :messages, :received_at, :delivered_at
  end
end
