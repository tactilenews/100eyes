# frozen_string_literal: true

class AddWhatsAppMessageFailedCountToContributors < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :whats_app_message_failed_count, :integer, default: 0
  end
end
