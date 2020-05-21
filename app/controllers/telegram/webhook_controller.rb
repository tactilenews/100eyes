# frozen_string_literal: true

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  def message(message)
    user = User.upsert_via_telegram(message)
    user.reply_via_telegram(message)
  end

  def start!(_data = nil, *)
    User.upsert_via_telegram('from' => from, 'chat' => chat)
    project_name = Rails.configuration.project_name
    response = I18n.t 'telegram.welcome_message', project_name: project_name
    respond_with :message, text: response.strip
  end
end
