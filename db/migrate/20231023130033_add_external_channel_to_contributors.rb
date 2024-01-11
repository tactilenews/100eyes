# frozen_string_literal: true

class AddExternalChannelToContributors < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :external_channel, :string
  end
end
