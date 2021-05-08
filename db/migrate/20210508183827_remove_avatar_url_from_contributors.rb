# frozen_string_literal: true

class RemoveAvatarUrlFromContributors < ActiveRecord::Migration[6.1]
  def change
    remove_column :contributors, :avatar_url, :string
  end
end
