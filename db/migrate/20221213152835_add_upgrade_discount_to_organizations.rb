# frozen_string_literal: true

class AddUpgradeDiscountToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :upgrade_discount, :integer
  end
end
