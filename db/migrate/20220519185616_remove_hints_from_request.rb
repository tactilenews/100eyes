# frozen_string_literal: true

class RemoveHintsFromRequest < ActiveRecord::Migration[6.1]
  def up
    remove_column :requests, :hints
  end

  def down
    add_column :requests, :hints, :string, array: true, default: []
  end
end
