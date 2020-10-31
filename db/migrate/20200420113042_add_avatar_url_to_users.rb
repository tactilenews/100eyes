# frozen_string_literal: true

class AddAvatarUrlToContributors < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :avatar_url, :string
  end
end
