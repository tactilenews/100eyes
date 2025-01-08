# frozen_string_literal: true

class AddSignalUsernameToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :signal_username, :string
  end
end
