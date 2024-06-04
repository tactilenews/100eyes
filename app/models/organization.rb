# frozen_string_literal: true

class Organization < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :business_plan
  belongs_to :contact_person, class_name: 'User', optional: true
  has_many :users, class_name: 'User', dependent: :destroy
  has_many :contributors, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_many :notifications_as_mentioned, class_name: 'ActivityNotification', dependent: :destroy

  before_update :notify_admin

  has_one_attached :onboarding_logo
  has_one_attached :onboarding_hero

  def all_tags_with_count
    ActsAsTaggableOn::Tag
      .for_tenant(id)
      .joins(:taggings)
      .select('tags.id, tags.name, count(taggings.id) as taggings_count')
      .group('tags.id')
      .all
      .map do |tag|
        {
          id: tag.id,
          name: tag.name,
          value: tag.name,
          count: tag.taggings_count,
          color: Contributor.tag_color_from_id(tag.id)
        }
      end
  end

  private

  def notify_admin
    return unless business_plan_id_changed? && upgraded_business_plan_at.present?

    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.send_business_plan_upgraded_message!(admin, self)
    end
  end
end
