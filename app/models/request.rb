# frozen_string_literal: true

class Request < ApplicationRecord
  include PlaceholderHelper
  include PgSearch::Model

  multisearchable against: %i[title text],
                  additional_attributes: ->(request) { { organization_id: request.organization_id } }

  belongs_to :user
  belongs_to :organization
  has_many :messages, dependent: :destroy
  has_many :contributors, through: :messages, source: :recipient
  has_many :photos, through: :messages
  default_scope { order(broadcasted_at: :desc) }
  has_many :notifications_as_mentioned, class_name: 'ActivityNotification', dependent: :destroy
  has_many_attached :files

  scope :include_associations, -> { preload(messages: :sender).includes([:tags, { messages: :files }]).eager_load(:messages) }
  scope :planned, -> { where.not(schedule_send_for: nil).where('schedule_send_for > ?', Time.current) }
  scope :broadcasted, -> { where.not(broadcasted_at: nil) }

  validates :files, blob: { content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif'] }
  validates :title, presence: true
  validates :text, length: { maximum: 1500 }, presence: true, unless: -> { files.attached? }

  acts_as_taggable_on :tags
  acts_as_taggable_tenant :organization_id

  after_create :broadcast_request

  after_update_commit :broadcast_updated_request

  delegate :replies, to: :messages
  delegate :outbound, to: :messages

  def personalized_text(contributor)
    replace_placeholder(text, I18n.t('request.personalization.first_name'), contributor.first_name.strip)
  end

  def stats
    {
      counts: {
        recipients: outbound.select(:recipient_id).distinct.count,
        contributors: replies.select(:sender_id).distinct.count,
        photos: replies.sum(:photos_count),
        replies: replies_count
      }
    }
  end

  def planned?
    schedule_send_for.present? && schedule_send_for > Time.current
  end

  def messages_by_contributor
    messages
      .includes(
        [
          { sender: { avatar_attachment: :blob } },
          { photos: { attachment_attachment: :blob } },
          { files: { attachment_attachment: :blob } },
          { recipient: { avatar_attachment: :blob } }
        ]
      )
      .where(broadcasted: false)
      .group_by(&:contributor)
      .transform_values { |messages| messages.sort_by(&:created_at) }
  end

  def self.broadcast!(request)
    if request.planned?
      BroadcastRequestJob.delay(run_at: request.schedule_send_for).perform_later(request.id)
      RequestScheduled.with(request_id: request.id, organization_id: request.organization.id).deliver_later(User.all)
    else
      Contributor.active.with_tags(request.tag_list).each do |contributor|
        message = Message.new(
          sender: request.user,
          recipient: contributor,
          text: request.personalized_text(contributor),
          request: request,
          broadcasted: true
        )
        message.files = attach_files(request.files) if request.files.attached?
        message.save!
      end
      request.update(broadcasted_at: Time.current)
    end
  end

  def self.attach_files(files)
    files.map do |file|
      message_file = Message::File.new
      message_file.attachment.attach(file.blob)
      message_file
    end
  end

  private

  def broadcast_request
    Request.broadcast!(self)
  end

  def broadcast_updated_request
    return unless saved_change_to_schedule_send_for?

    Request.broadcast!(self)
  end
end
