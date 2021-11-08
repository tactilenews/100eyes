# frozen_string_literal: true

class AddAdditionalEmailToContributorsTable < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :additional_email, :string
  end
end
