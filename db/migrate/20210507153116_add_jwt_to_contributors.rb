# frozen_string_literal: true

class AddJwtToContributors < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :jwt, :string
  end
end
