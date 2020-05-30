# frozen_string_literal: true

class Message < ApplicationRecord
  include PgSearch::Model

  default_scope { order(created_at: :desc) }

  multisearchable against: :text

  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :recipient, class_name: 'User', optional: true
  belongs_to :request
  counter_culture :request, column_name: proc { |model| model.reply? ? 'replies_count' : nil }

  has_many :photos, dependent: :destroy

  after_create do
    send_email
    send_telegram_message
  end

  def reply?
    !!sender_id
  end

  private

  def send_email
    return unless recipient&.email

    MessageMailer
      .with(message: text, to: recipient.email)
      .new_message_email
      .deliver_later
  end

  def send_telegram_message
    return unless recipient&.telegram_chat_id

    Telegram.bots[Rails.configuration.bot_id].send_message(
      chat_id: recipient.telegram_chat_id,
      text: text
    )
  end
end
