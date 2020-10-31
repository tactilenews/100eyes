# frozen_string_literal: true

class AddAdditionalFieldsToContributors < ActiveRecord::Migration[6.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :street
      t.string :zip_code
      t.string :city
      t.string :phone
    end
  end
end
