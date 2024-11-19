# frozen_string_literal: true

class AddExternalFileIdsToRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :requests, :external_file_ids, :string, array: true, default: []
    add_index :requests, :external_file_ids, using: 'gin'
  end
end
