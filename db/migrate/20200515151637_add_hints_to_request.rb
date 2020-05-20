# frozen_string_literal: true

class AddHintsToRequest < ActiveRecord::Migration[6.0]
  def change
    add_column :requests, :hints, :string, array: true, default: []
  end
end
