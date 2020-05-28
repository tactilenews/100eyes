# frozen_string_literal: true

class AddCounterCaches < ActiveRecord::Migration[6.0]
  def change
    add_column :requests, :replies_count, :integer
    add_column :replies, :photos_count, :integer
  end
end
