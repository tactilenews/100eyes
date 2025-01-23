# frozen_string_literal: true

class AddOrganizationIdToMessages < ActiveRecord::Migration[6.1]
  def change
    add_reference :messages, :organization, foreign_key: true
  end
end
