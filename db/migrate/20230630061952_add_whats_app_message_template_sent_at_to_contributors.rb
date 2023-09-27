# frozen_string_literal: true

class AddWhatsAppMessageTemplateSentAtToContributors < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :whats_app_message_template_sent_at, :datetime, default: nil, null: true
  end
end
