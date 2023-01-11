# frozen_string_literal: true

class AddWhatsAppToContributors < ActiveRecord::Migration[6.1]
  def change
    change_table(:contributors, bulk: true) do |t|
      t.column :whats_app_phone_number, :string, unique: true
      t.column :whats_app_template_message_sent_at, :datetime, default: nil, null: true
      t.column :latest_message_received_at, :datetime, default: nil, null: true
      t.index [:whats_app_phone_number], unique: true
    end
  end
end
