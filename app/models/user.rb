# frozen_string_literal: true

class User < ApplicationRecord
  include PgSearch::Model
  multisearchable against: %i[first_name last_name username note]
  has_many :replies, class_name: 'Message', inverse_of: :sender, foreign_key: 'sender_id', dependent: :destroy
  has_many :received_messages, class_name: 'Message', inverse_of: :recipient, foreign_key: 'recipient_id', dependent: :destroy
  has_many :replied_to_requests, -> { reorder(created_at: :desc).distinct }, source: :request, through: :replies
  has_many :received_requests, -> { reorder(created_at: :desc).distinct }, source: :request, through: :received_messages
  default_scope { order(:first_name, :last_name) }
  validates :email, presence: false, 'valid_email_2/email': true

  before_validation do
    self.email = nil if email.blank?
  end

  def reply(message_decorator)
    request = active_request or return nil
    ActiveRecord::Base.transaction do
      message = message_decorator.message
      message.request = request
      message.save!
      message.photos << message_decorator.photos
    end
  end

  def name
    "#{first_name} #{last_name}"
  end

  def name=(full_name)
    first_name, last_name = full_name.split(' ')
    self.first_name = first_name
    self.last_name = last_name
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
    received_requests.reorder(created_at: :desc).first
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
end
