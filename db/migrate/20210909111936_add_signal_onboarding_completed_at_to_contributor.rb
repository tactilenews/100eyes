# frozen_string_literal: true

class AddSignalOnboardingCompletedAtToContributor < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :signal_onboarding_completed_at, :datetime, default: nil, null: true
  end
end
