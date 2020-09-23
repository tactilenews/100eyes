# frozen_string_literal: true

class CreateVoices < ActiveRecord::Migration[6.0]
  def change
    create_table :voices do |t|
      t.references :message, null: false, foreign_key: true

      t.timestamps
    end
  end
end
