# frozen_string_literal: true

class UpdateSignalAttrsOnContributors < ActiveRecord::Migration[6.1]
  def change
    change_table :contributors, bulk: true do |t|
      t.remove :signal_onboarding_completed_at, type: :datetime
      t.column :signal_uuid, :string, default: nil
      t.column :signal_username, :string, default: nil
    end
  end
end
