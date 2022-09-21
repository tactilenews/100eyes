# frozen_string_literal: true

class CreateActivityNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :activity_notifications do |t|
      t.references :recipient, polymorphic: true, null: false
      t.string :type, null: false
      t.jsonb :params
      t.datetime :read_at

      t.timestamps
    end
    add_index :activity_notifications, :read_at
  end
end
