# frozen_string_literal: true

class RemoveOrganizationIdFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_reference :users, :organization, foreign_key: true, index: true
  end
end
