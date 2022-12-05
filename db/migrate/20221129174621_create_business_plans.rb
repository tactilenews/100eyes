# frozen_string_literal: true

class CreateBusinessPlans < ActiveRecord::Migration[6.1]
  def change
    create_table :business_plans do |t|
      t.string :name
      t.integer :price_per_month
      t.integer :setup_cost
      t.integer :hours_of_included_support
      t.integer :number_of_users
      t.integer :number_of_contributors
      t.integer :number_of_communities
      t.datetime :vaild_from
      t.datetime :valid_until

      t.timestamps
    end
  end
end
