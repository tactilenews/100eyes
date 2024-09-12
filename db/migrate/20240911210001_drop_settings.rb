# frozen_string_literal: true

class DropSettings < ActiveRecord::Migration[6.1]
  def change
    drop_table :settings do |t|
      t.string 'var', null: false
      t.text 'value'
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
      t.index ['var'], name: 'index_settings_on_var', unique: true
    end
  end
end
