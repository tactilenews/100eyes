# frozen_string_literal: true

class Message < ApplicationRecord
  include PgSearch::Model

  default_scope { order(created_at: :desc) }

  multisearchable against: :text, if: :reply?

  belongs_to :sender, class_name: 'Contributor', optional: true
  belongs_to :recipient, class_name: 'Contributor', optional: true
  belongs_to :request
  has_many :photos, dependent: :destroy
  has_one :voice, dependent: :destroy

  counter_culture :request, column_name: proc { |model| model.reply? ? 'replies_count' : nil }

  scope :replies, -> { where.not(sender_id: nil) }

  has_many_attached :raw_data
  validates :raw_data, presence: true, if: -> { sender.present? }
  validates :unknown_content, inclusion: { in: [true, false] }

  after_create do
    [PostmarkAdapter::Outbound, TelegramAdapter::Outbound].each do |klass|
      adapter = klass.new(message: self)
      adapter.send!
    end
  end

  def reply?
    sender_id.present?
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
end
