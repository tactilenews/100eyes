# frozen_string_literal: true

unless Rails.env.production?
  bot_files = Dir[Rails.root.join('app/facebook_bot/**/*.rb')]
  bot_reloader = ActiveSupport::FileUpdateChecker.new(bot_files) do
    bot_files.each { |file| require_dependency file }
  end

  ActiveSupport::Reloader.to_prepare do
    bot_reloader.execute_if_updated
  end

  bot_files.each { |file| require_dependency file }
end

Facebook::Messenger.configure do |config|
  config.provider = CredentialsProvider.new
end

if Rails.configuration.facebook_page_id
  Facebook::Messenger::Subscriptions.subscribe(
    access_token: Facebook::Messenger.config.provider.access_token_for,
    subscribed_fields: %w[messages]
  )
end
