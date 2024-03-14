# frozen_string_literal: true

class ChangePhotosCountDefaultOnMessages < ActiveRecord::Migration[6.1]
  def up
    change_column :messages, :photos_count, :integer, default: 0
  end

  def down
    change_column :messages, :photos_count, :integer, default: nil
  end
end
