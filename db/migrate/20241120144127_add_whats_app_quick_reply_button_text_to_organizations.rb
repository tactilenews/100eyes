# frozen_string_literal: true

class AddWhatsAppQuickReplyButtonTextToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :whats_app_quick_reply_button_text, :jsonb, default: { answer_request: 'Antworten', more_info: 'Mehr Infos' }
  end
end
