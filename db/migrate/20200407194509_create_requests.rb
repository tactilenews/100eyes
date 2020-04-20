# frozen_string_literal: true

class CreateRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :requests do |t|
      t.string :title
      t.string :text

      t.timestamps
    end
  end
end
