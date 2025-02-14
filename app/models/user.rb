# frozen_string_literal: true

class User < ApplicationRecord
  include Clearance::User

  has_many :notifications_as_recipient,
           as: :recipient,
           class_name: 'ActivityNotification',
           dependent: :destroy
  has_many :notifications_as_mentioned, class_name: 'ActivityNotification', dependent: :destroy
  has_many :messages, as: :sender, dependent: :destroy
  has_many :users_organizations, dependent: :destroy
  has_many :organizations, through: :users_organizations

  has_one_time_password
  validates :password, length: { in: 8..128 }, unless: :skip_password_validation?
  validates :organizations, length: { minimum: 1 }, unless: :admin?

  scope :admin, ->(boolean = true) { where(admin: boolean) }
  scope :active, -> { where(deactivated_at: nil) }
  scope :inactive, -> { where.not(deactivated_at: nil) }

  after_create_commit :notify_admin
  after_update_commit :reset_otp

  def name
    "#{first_name} #{last_name}"
  end

  def avatar?
    false
  end

  def active?
    deactivated_at.nil?
  end

  alias active active?

  def inactive?
    !active?
  end

  alias inactive inactive?

  def active=(value)
    self.deactivated_at = ActiveModel::Type::Boolean.new.cast(value) ? nil : Time.current
  end

  private

  def notify_admin
    return unless organizations.any? { |organization| organization.users.admin(false).count > organization.business_plan.number_of_users }

    User.admin.find_each do |admin|
      organizations.each do |organization|
        next unless organization.users.admin(false).count > organization.business_plan.number_of_users

        PostmarkAdapter::Outbound.send_user_count_exceeds_plan_limit_message!(admin, organization)
      end
    end
  end

  def reset_otp
    return unless saved_change_to_otp_enabled? && otp_enabled_previously_was == true

    update(otp_secret_key: User.otp_random_secret)
  end
end
