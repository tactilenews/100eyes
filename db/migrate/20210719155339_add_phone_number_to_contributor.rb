# frozen_string_literal: true

class AddPhoneNumberToContributor < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :phone_number, :string, unique: true
    add_index :contributors, :phone_number, unique: true
  end
end
