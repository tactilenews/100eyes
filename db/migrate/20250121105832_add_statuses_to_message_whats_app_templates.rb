# frozen_string_literal: true

class AddStatusesToMessageWhatsAppTemplates < ActiveRecord::Migration[6.1]
  def change
    change_table :message_whats_app_templates, bulk: true do |t|
      t.datetime :sent_at
      t.datetime :delivered_at
      t.datetime :read_at
    end
  end
end
