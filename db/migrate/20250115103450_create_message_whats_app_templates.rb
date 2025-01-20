# frozen_string_literal: true

class CreateMessageWhatsAppTemplates < ActiveRecord::Migration[6.1]
  def change
    create_table :message_whats_app_templates do |t|
      t.references :message, null: false, foreign_key: true
      t.string :external_id

      t.timestamps
    end
    add_index :message_whats_app_templates, :external_id
  end
end
