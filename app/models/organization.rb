# frozen_string_literal: true

class Organization < ApplicationRecord
  belongs_to :business_plan
  belongs_to :contact_person, class_name: 'User', optional: true
  has_many :users, class_name: 'User', dependent: :destroy
  has_many :contributors, dependent: :destroy

  before_update :notify_admin

  private

  def notify_admin
    return unless business_plan_id_changed? && upgraded_business_plan_at.present?

    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.send_business_plan_upgraded_message!(admin, self)
    end
  end
end
