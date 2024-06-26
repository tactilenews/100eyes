# frozen_string_literal: true

class UpdateSignalAttrsOnContributors < ActiveRecord::Migration[6.1]
  def change
    change_table :contributors, bulk: true do |t|
      t.column :signal_uuid, :string, default: nil
      t.column :signal_onboarding_token, :string, unique: true
    end
  end
end
