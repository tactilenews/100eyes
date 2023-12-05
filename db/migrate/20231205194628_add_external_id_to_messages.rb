# frozen_string_literal: true

class AddExternalIdToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :external_id, :string
  end
end
