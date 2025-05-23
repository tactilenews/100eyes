# frozen_string_literal: true

class Message < ApplicationRecord
  include PgSearch::Model

  default_scope { order(created_at: :desc) }

  multisearchable against: :text, if: :reply?,
                  additional_attributes: ->(message) { { organization_id: message.organization.id } }

  belongs_to :sender, polymorphic: true, optional: true
  belongs_to :recipient, class_name: 'Contributor', optional: true
  belongs_to :creator, class_name: 'User', optional: true
  belongs_to :request, optional: true
  belongs_to :organization

  has_many :files, dependent: :destroy, class_name: 'Message::File'
  has_many :notifications_as_mentioned, class_name: 'ActivityNotification', dependent: :destroy
  has_one :whats_app_template, dependent: :destroy, class_name: 'Message::WhatsAppTemplate'

  counter_culture :request,
                  column_name: proc { |model| model.reply? ? 'replies_count' : nil },
                  column_names: lambda {
                    {
                      Message.replies => 'replies_count'
                    }
                  }

  scope :replies, -> { where(sender_type: Contributor.name) }
  scope :outbound, -> { where(sender_type: [User.name, nil]) }
  scope :direct_messages, -> { outbound.where(broadcasted: false) }
  scope :broadcasted_messages, -> { where(broadcasted: true) }
  scope :with_request_attached, -> { where.not(request_id: nil) }

  delegate :name, to: :creator, allow_nil: true, prefix: true

  has_many_attached :raw_data
  validates :raw_data, presence: true, if: -> { sent_from_contributor? }
  validates :unknown_content, inclusion: { in: [true, false] }

  after_create_commit :notify_recipient

  def send!
    [PostmarkAdapter::Outbound, SignalAdapter::Outbound, TelegramAdapter::Outbound, ThreemaAdapter::Outbound,
     WhatsAppAdapter::ThreeSixtyDialogOutbound].each do |adapter|
      adapter.send!(self)
    end
  end

  def reply?
    sent_from_contributor?
  end

  def manually_created?
    creator_id.present?
  end

  def sender_name
    return sender.name if sender

    organization.project_name
  end

  def contributor
    recipient || sender # If there is no recipient, then the message must be inbound and the sender must be a contributor
  end

  def chat_message_link
    Rails.application.routes.url_helpers.conversations_organization_contributor_path(organization, id: contributor, anchor: "message-#{id}")
  end

  def sent_from_contributor?
    sender.is_a? Contributor
  end

  def read_at=(datetime)
    super

    self.delivered_at = datetime if delivered_at.blank?
  end

  private

  # rubocop:disable Metrics/AbcSize
  def notify_recipient
    if reply?
      MessageReceived.with(
        contributor_id: sender_id,
        request_id: request&.id,
        message_id: id,
        organization_id: organization.id
      ).deliver_later(organization.users + User.admin.all)
    elsif !broadcasted?
      ChatMessageSent.with(
        contributor_id: recipient.id,
        request_id: request&.id,
        user_id: sender_id,
        message_id: id,
        organization_id: organization.id
      ).deliver_later(organization.users + User.admin.all)
    end
  end
  # rubocop:enable Metrics/AbcSize
end
