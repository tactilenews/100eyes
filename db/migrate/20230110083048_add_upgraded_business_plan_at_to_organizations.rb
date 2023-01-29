# frozen_string_literal: true

class AddUpgradedBusinessPlanAtToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :upgraded_business_plan_at, :datetime, default: nil
  end
end
