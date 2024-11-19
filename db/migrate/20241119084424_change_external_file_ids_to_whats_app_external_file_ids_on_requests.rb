# frozen_string_literal: true

class ChangeExternalFileIdsToWhatsAppExternalFileIdsOnRequests < ActiveRecord::Migration[6.1]
  def change
    rename_column :requests, :external_file_ids, :whats_app_external_file_ids
  end
end
