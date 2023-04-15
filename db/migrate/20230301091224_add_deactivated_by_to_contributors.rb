# frozen_string_literal: true

class AddDeactivatedByToContributors < ActiveRecord::Migration[6.1]
  def change
    change_table(:contributors, bulk: true) do |t|
      t.column :deactivated_by_user_id, :bigint, default: nil, null: true
      t.column :deactivated_by_admin, :boolean, default: false
    end
  end
end
