# frozen_string_literal: true

Rails.application.configure do
  config.after_initialize do
    config = {}
    if ActiveRecord::Base.connection.table_exists? Organization.table_name
      Organization.find_each do |org|
        next unless org.respond_to?(:telegram_bot_api_key) && org.telegram_configured?

        config[org.id] = { token: org.telegram_bot_api_key, username: org.telegram_bot_username }
      end
    end
    Telegram.bots_config = config

  rescue ActiveRecord::NoDatabaseError
    nil
  end
end
