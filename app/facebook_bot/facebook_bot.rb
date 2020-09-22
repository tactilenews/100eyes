# frozen_string_literal: true

Facebook::Messenger::Subscriptions.subscribe(
  access_token: Facebook::Messenger.config.provider.access_token_for,
  subscribed_fields: %w[messages]
)

Facebook::Messenger::Bot.on :message do |message|
  fm = FacebookMessage.new(message)
  message.reply(text: I18n.t('facebook.unknown_content_message')) if fm.unknown_content
  user = fm.sender
  user.save!
  user.reply(fm)
end
