# frozen_string_literal: true

class Message < ApplicationRecord
  include PgSearch::Model

  default_scope { order(created_at: :desc) }

  multisearchable against: :text, if: :reply?

  belongs_to :sender, polymorphic: true, optional: true
  belongs_to :recipient, class_name: 'Contributor', optional: true
  belongs_to :creator, class_name: 'User', optional: true
  belongs_to :request
  has_many :photos, dependent: :destroy
  has_many :files, dependent: :destroy, class_name: 'Message::File'
  has_many :notifications_as_mentioned, class_name: 'ActivityNotification', dependent: :destroy

  counter_culture :request, column_name: proc { |model| model.reply? ? 'replies_count' : nil }

  scope :replies, -> { where(sender_type: Contributor.name) }

  delegate :name, to: :creator, allow_nil: true, prefix: true

  has_many_attached :raw_data
  validates :raw_data, presence: true, if: -> { sent_from_contributor? }
  validates :unknown_content, inclusion: { in: [true, false] }

  after_create_commit :send_if_outbound
  after_create_commit :notify_recipient

  def reply?
    sent_from_contributor?
  end

  def manually_created?
    creator_id.present?
  end

  def sender_name
    return sender.name if sender

    Setting.project_name
  end

  def contributor
    recipient || sender # If there is no recipient, then the message must be inbound and the sender must be a contributor
  end

  def conversation_link
    Rails.application.routes.url_helpers.contributor_request_path(id: request.id, contributor_id: contributor.id)
  end

  def chat_message_link
    Rails.application.routes.url_helpers.contributor_request_path(
      contributor,
      request,
      anchor: "message-#{id}"
    )
  end

  def sent_from_contributor?
    sender.is_a? Contributor
  end

  private

  def notify_recipient
    if reply?
      MessageReceived.with(contributor_id: sender_id, request_id: request.id, message_id: id).deliver_later(User.all)
    elsif !broadcasted?
      ChatMessageSent.with(contributor_id: recipient.id, request_id: request.id, user_id: sender_id,
                           message_id: id).deliver_later(User.all)
    end
  end

  def send_if_outbound
    return if manually_created? || reply?

    [PostmarkAdapter::Outbound, SignalAdapter::Outbound, TelegramAdapter::Outbound, ThreemaAdapter::Outbound,
     WhatsAppAdapter::Outbound].each do |adapter|
      adapter.send!(self)
    end
  end
end
