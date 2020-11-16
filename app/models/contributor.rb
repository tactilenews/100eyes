# frozen_string_literal: true

class Contributor < ApplicationRecord
  include PgSearch::Model
  multisearchable against: %i[first_name last_name username note]

  has_many :replies, class_name: 'Message', inverse_of: :sender, foreign_key: 'sender_id', dependent: :destroy
  has_many :received_messages, class_name: 'Message', inverse_of: :recipient, foreign_key: 'recipient_id', dependent: :destroy
  has_many :replied_to_requests, -> { reorder(created_at: :desc).distinct }, source: :request, through: :replies
  has_many :received_requests, -> { reorder(created_at: :desc).distinct }, source: :request, through: :received_messages

  acts_as_taggable_on :tags

  default_scope { order(:first_name, :last_name) }
  scope :active, -> { where(deactivated_at: nil) }

  validates :email, uniqueness: { case_sensitive: false }, allow_nil: true, 'valid_email_2/email': true

  scope :with_tags, lambda { |tag_list = []|
    tag_list.blank? ? all : tagged_with(tag_list)
  }

  before_validation do
    self.email = nil if email.blank?
  end

  def self.with_lowercased_email(email)
    find_by('lower(email) in (?)', Array.wrap(email).map(&:downcase))
  end

  def self.email_taken?(email)
    contributor = Contributor.new(email: email)
    contributor.valid?

    error_types = contributor.errors.details[:email].pluck(:error)

    error_types.include?(:taken)
  end

  def self.all_tags_with_count
    Contributor.all_tags.map do |tag|
      {
        id: tag.id,
        name: tag.name,
        value: tag.name,
        count: Contributor.tagged_with([tag]).count
      }
    end
  end

  def reply(message_decorator)
    request = active_request or return nil
    ActiveRecord::Base.transaction do
      message = message_decorator.message
      message.request = request
      message.save!
    end
  end

  def name
    "#{first_name} #{last_name}"
  end

  def conversation_about(request)
    Message
      .where(request: request, sender: self)
      .or(Message.where(request: request, recipient: self))
      .reorder(created_at: :asc)
  end

  def channels
    { email: email?, telegram: telegram? }.select { |_k, v| v }.keys
  end

  def active_request
    received_requests.reorder(created_at: :desc).first || Request.reorder(created_at: :desc).first
  end

  def telegram?
    telegram_id.present? && telegram_chat_id.present?
  end

  def email?
    email.present?
  end

  def recent_replies
    result = replies.eager_load(:request, :sender).reorder(created_at: :desc)
    result = result.group_by(&:request).values # array or groups
    result = result.map(&:first) # choose most recent message per group
    result.sort_by(&:created_at).reverse # ensure descending order
  end

  def active?
    deactivated_at.nil?
  end
  alias active active?

  def active=(value)
    self.deactivated_at = ActiveModel::Type::Boolean.new.cast(value) ? nil : Time.current
  end
end
