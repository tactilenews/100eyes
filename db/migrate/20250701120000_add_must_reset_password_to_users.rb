# frozen_string_literal: true

class AddMustResetPasswordToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :must_reset_password, :boolean, null: false, default: false
  end
end
