# frozen_string_literal: true

class Request < ApplicationRecord
  include PlaceholderHelper

  belongs_to :user
  has_many :messages, dependent: :destroy
  has_many :contributors, through: :messages, source: :recipient
  has_many :photos, through: :messages
  default_scope { order(created_at: :desc) }
  has_many :notifications_as_mentioned, class_name: 'ActivityNotification', dependent: :destroy
  has_many_attached :files

  scope :include_associations, -> { preload(messages: :sender).includes(messages: :files).eager_load(:messages) }
  scope :planned, -> { where.not(schedule_send_for: nil).where('schedule_send_for > ?', Time.current) }
  scope :sent, -> { where(schedule_send_for: nil).or(where('schedule_send_for < ?', Time.current)) }

  validates :files, blob: { content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif'] }
  validates :title, presence: true
  validates :text, length: { maximum: 1500 }, presence: true

  acts_as_taggable_on :tags

  after_create { Request.broadcast!(self) }

  after_update_commit :broadcast_updated_request, :notify_recipient

  delegate :replies, to: :messages

  def personalized_text(contributor)
    replace_placeholder(text, I18n.t('request.personalization.first_name'), contributor.first_name.strip)
  end

  def stats
    {
      counts: {
        recipients: messages.map(&:recipient_id).compact.uniq.size,
        contributors: messages.select(&:reply?).map(&:sender_id).compact.uniq.size,
        photos: messages.replies.map do |message|
          message.photos_count ||
            message.files.joins(:attachment_blob).where(active_storage_blobs: { content_type: %w[image/jpg image/jpeg
                                                                                                 image/png image/gif] }).size ||
            0
        end.sum,
        replies: messages.count(&:reply?)
      }
    }
  end

  def planned?
    schedule_send_for.present? && schedule_send_for > Time.current
  end

  def messages_by_contributor
    messages
      .where(broadcasted: false)
      .group_by(&:contributor)
      .transform_values { |messages| messages.sort_by(&:created_at) }
  end

  def self.broadcast!(request)
    if request.planned?
      BroadcastRequestJob.delay(run_at: request.schedule_send_for).perform_later(request.id)
      RequestScheduled.with(request_id: request.id).deliver_later(User.all)
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

  def broadcast_updated_request
    return unless planned? && saved_change_to_schedule_send_for?

    Request.broadcast!(self)
  end

  def notify_recipient
    return unless saved_change_to_schedule_send_for?

    RequestScheduled.with(request_id: id).deliver_later(User.all)
  end
end
