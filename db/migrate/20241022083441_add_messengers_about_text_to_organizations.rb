# frozen_string_literal: true

class AddMessengersAboutTextToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :messengers_about_text, :string
  end
end
