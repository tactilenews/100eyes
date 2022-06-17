# frozen_string_literal: true

class Message < ApplicationRecord
  include PgSearch::Model

  default_scope { order(created_at: :desc) }

  multisearchable against: :text, if: :reply?

  belongs_to :sender, class_name: 'Contributor', optional: true
  belongs_to :recipient, class_name: 'Contributor', optional: true
  belongs_to :creator, class_name: 'User', optional: true
  belongs_to :request
  has_many :photos, dependent: :destroy
  has_many :files, dependent: :destroy, class_name: 'Message::File'

  counter_culture :request, column_name: proc { |model| model.reply? ? 'replies_count' : nil }

  scope :replies, -> { where.not(sender_id: nil) }

  delegate :name, to: :creator, allow_nil: true, prefix: true

  has_many_attached :raw_data
  validates :raw_data, presence: true, if: -> { sender.present? }
  validates :unknown_content, inclusion: { in: [true, false] }

  after_commit(on: :create, unless: :manually_created?) do
    [PostmarkAdapter::Outbound, SignalAdapter::Outbound, TelegramAdapter::Outbound, ThreemaAdapter::Outbound].each do |adapter|
      adapter.send!(self)
    end
  end

  after_create_commit :notify_recipient, if: :reply?

  def reply?
    sender_id.present?
  end

  def manually_created?
    creator_id.present?
  end

  def sender_name
    return sender.name if sender

    Setting.project_name
  end

  def contributor
    sender || recipient
  end

  def conversation_link
    Rails.application.routes.url_helpers.contributor_request_path(id: request.id, contributor_id: contributor.id)
  end

  def chat_message_link
    Rails.application.routes.url_helpers.contributor_request_path(
      contributor,
      request,
      anchor: "chat-row-#{id}"
    )
  end

  private

  def notify_recipient
    MessageReceived.with(contributor: sender, request: request).deliver_later(User.all)
  end
end
