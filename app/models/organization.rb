# frozen_string_literal: true

class Organization < ApplicationRecord
  belongs_to :business_plan
  belongs_to :contact_person, class_name: 'User', optional: true
  has_many :users, class_name: 'User', dependent: :destroy
  has_many :contributors, dependent: :destroy

  has_one_attached :onboarding_logo
  has_one_attached :onboarding_hero
  has_one_attached :channel_image

  before_update :notify_admin
  after_commit :notify_admin_of_welcome_message_change

  private

  def notify_admin
    return unless business_plan_id_changed? && upgraded_business_plan_at.present?

    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.send_business_plan_upgraded_message!(admin, self)
    end
  end

  def notify_admin_of_welcome_message_change
    return unless saved_change_to_onboarding_success_heading? || saved_change_to_onboarding_success_text?

    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.welcome_message_updated!(admin, self)
    end
  end
end
