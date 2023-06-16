# frozen_string_literal: true

class RemoveWhatsAppMessageTemplateAttrsFromContributor < ActiveRecord::Migration[6.1]
  def up
    change_table(:contributors, bulk: true) do |t|
      t.remove :whats_app_template_message_sent_at
    end
  end

  def down
    change_table(:contributors, bulk: true) do |t|
      t.column :whats_app_template_message_sent_at, :datetime, default: nil, null: true
    end
  end
end
