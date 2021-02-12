# frozen_string_literal: true

class RenameVoicesToMessageFiles < ActiveRecord::Migration[6.0]
  def change
    rename_table :voices, :message_files
  end
end
