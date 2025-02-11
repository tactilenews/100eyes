# frozen_string_literal: true

class AddReplyToExternalIdToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :reply_to_external_id, :string
  end
end
