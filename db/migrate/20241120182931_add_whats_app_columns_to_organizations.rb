# frozen_string_literal: true

class AddWhatsAppColumnsToOrganizations < ActiveRecord::Migration[6.1]
  def change
    change_table :organizations, bulk: true do |t|
      t.jsonb :whats_app_quick_reply_button_text, default: { answer_request: 'Antworten', more_info: 'Mehr Infos' }
      t.string :whats_app_more_info_message, default: ''
    end
  end
end
