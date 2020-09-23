# frozen_string_literal: true

class TurnFacebookIdIntoString < ActiveRecord::Migration[6.0]
  def change
    change_column :users, :facebook_id, :string
  end
end
