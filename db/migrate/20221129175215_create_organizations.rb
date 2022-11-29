# frozen_string_literal: true

class CreateOrganizations < ActiveRecord::Migration[6.1]
  def change
    create_table :organizations do |t|
      t.string :name

      t.timestamps
      t.references :business_plan, null: false, foreign_key: true
    end
  end
end
