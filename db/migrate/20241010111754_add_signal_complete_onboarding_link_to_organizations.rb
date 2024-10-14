# frozen_string_literal: true

class AddSignalCompleteOnboardingLinkToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :signal_complete_onboarding_link, :string
  end
end
