# frozen_string_literal: true

class User < ApplicationRecord
  include Clearance::User

  has_many :notifications_as_recipient,
           as: :recipient,
           class_name: 'ActivityNotification',
           dependent: :destroy
  has_many :notifications_as_mentioned, class_name: 'ActivityNotification', dependent: :destroy
  has_many :messages, as: :sender, dependent: :destroy

  has_one_time_password
  validates :password, length: { in: 8..128 }, unless: :skip_password_validation?

  after_update_commit :reset_otp

  def name
    "#{first_name} #{last_name}"
  end

  def avatar?
    false
  end

  private

  def reset_otp
    return unless saved_change_to_otp_enabled?

    update(otp_secret_key: User.otp_random_secret)
  end
end
