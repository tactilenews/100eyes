# frozen_string_literal: true

class ChangeDefaultValueForWhatsAppQuickReplyButtonsAnswerRequestOnOrganizations < ActiveRecord::Migration[6.1]
  def change
    change_column_default :organizations, :whats_app_quick_reply_button_text,
                          from: { answer_request: 'Antworten', more_info: 'Mehr Infos' },
                          to: { answer_request: 'Öffnen', more_info: 'Mehr Infos' }
  end
end
