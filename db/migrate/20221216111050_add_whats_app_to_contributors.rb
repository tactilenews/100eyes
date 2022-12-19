# frozen_string_literal: true

class AddWhatsAppToContributors < ActiveRecord::Migration[6.1]
  def change
    change_table(:contributors, bulk: true) do |t|
      t.column :whats_app_phone_number, :string
      t.column :whats_app_onboarding_completed_at, :datetime, default: nil, null: true
    end
  end
end
