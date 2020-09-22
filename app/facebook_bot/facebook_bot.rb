# frozen_string_literal: true

Facebook::Messenger::Subscriptions.subscribe(
  access_token: Facebook::Messenger.config.provider.access_token_for,
  subscribed_fields: %w[messages]
)

Facebook::Messenger::Bot.on :message do |message|
  message.reply(text: 'Hello, human!')
end
