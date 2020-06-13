Rails.application.configure do
  config.bot_id = (ENV['BOT'] || :default).to_sym
end
