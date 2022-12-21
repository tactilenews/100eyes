# frozen_string_literal: true

class User < ApplicationRecord
  include Clearance::User

  has_many :notifications_as_recipient,
           as: :recipient,
           class_name: 'ActivityNotification',
           dependent: :destroy
  has_many :notifications_as_mentioned, class_name: 'ActivityNotification', dependent: :destroy
  has_many :messages, as: :sender, dependent: :destroy
  belongs_to :organization, optional: true

  has_one_time_password
  validates :password, length: { in: 8..128 }, unless: :skip_password_validation?

  scope :admin, ->(boolean = true) { where(admin: boolean) }

  after_create_commit :notify_admin

  def name
    "#{first_name} #{last_name}"
  end

  def avatar?
    false
  end

  private

  def notify_admin
    return unless organization && User.admin(false).count > organization.business_plan.number_of_users

    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.send_user_count_exceeds_plan_limit_message!(admin, organization)
    end
  end
end
