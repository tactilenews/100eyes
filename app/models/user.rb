# frozen_string_literal: true

class User < ApplicationRecord
  include PgSearch::Model
  multisearchable against: %i[first_name last_name username note]
  has_many :replies, class_name: 'Message', inverse_of: :sender, foreign_key: 'sender_id', dependent: :destroy
  has_many :requests, -> { reorder(created_at: :desc).distinct }, through: :replies
  default_scope { order(:first_name, :last_name) }
  validates :email, presence: false, 'valid_email_2/email': true

  before_validation do
    self.email = nil if email.blank?
  end

  def reply_via_telegram(telegram_message)
    request = Request.active_request or return nil
    ActiveRecord::Base.transaction do
      message = telegram_message.message
      message.sender = self
      message.request = request
      message.save!
      message.photos << telegram_message.photos
    end
  end

  def reply_via_mail(mail)
    user = self
    request = Request.active_request or return nil
    Message.create!(request: request, text: mail.decoded, sender: user)
  end

  def name
    "#{first_name} #{last_name}"
  end

  def name=(full_name)
    first_name, last_name = full_name.split(' ')
    self.first_name = first_name
    self.last_name = last_name
  end

  def replies_for_request(request)
    replies.where(request_id: request).reorder(created_at: :asc)
  end

  def channels
    { email: email?, telegram: telegram? }.select { |_k, v| v }.keys
  end

  def telegram?
    telegram_id.present? && telegram_chat_id.present?
  end

  def email?
    email.present?
  end
end
