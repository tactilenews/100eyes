# frozen_string_literal: true

class Message < ApplicationRecord
  include PgSearch::Model

  default_scope { order(created_at: :desc) }

  multisearchable against: :text, if: :reply?

  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :recipient, class_name: 'User', optional: true
  belongs_to :request
  has_many :photos, dependent: :destroy

  counter_culture :request, column_name: proc { |model| model.reply? ? 'replies_count' : nil }

  scope :replies, -> { where.not(sender_id: nil) }

  has_many_attached :raw_data
  validates :raw_data, presence: true, if: -> { sender.present? }

  after_create do
    send_email
    send_telegram_message
  end

  def reply?
    sender_id.present?
  end

  def sender_name
    return sender.name if sender

    I18n.t('application_name')
  end

  def conversation_link
    user = sender || recipient
    Rails.application.routes.url_helpers.user_request_path(id: request.id, user_id: user.id)
  end

  def chat_message_link
    user = sender || recipient
    Rails.application.routes.url_helpers.user_request_path(
      user,
      request,
      anchor: "chat-row-#{id}"
    )
  end

  def self.renew!(message)
    ActiveRecord::Base.transaction do
      message.photos.destroy_all
      message.raw_data.each do |raw|
        mapping = {
          'application/json' => TelegramMessage,
          'message/rfc822' => EmailMessage
        }
        decorator_class = mapping[raw.content_type]
        break unless decorator_class

        message_decorator = decorator_class.from(raw)

        message.text = message_decorator.message.text
        message.save!
        message.photos << message_decorator.photos
      end
    end
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
