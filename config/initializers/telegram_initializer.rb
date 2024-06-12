# frozen_string_literal: true

Rails.application.configure do
  config.after_initialize do
    Telegram.bots_config = {
      default: {
        token: Setting.telegram_bot_api_key,
        username: Setting.telegram_bot_username
      }
    }
    Organization.find_each do |organization|
      Telegram.bots_config[organization.slug.underscore.to_sym] = {
        token: organization.telegram_bot_api_key,
        username: organization.telegram_bot_username
      }
    end

  rescue ActiveRecord::NoDatabaseError
    nil
  end
end
