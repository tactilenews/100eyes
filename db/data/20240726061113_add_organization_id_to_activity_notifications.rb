# frozen_string_literal: true

class AddOrganizationIdToActivityNotifications < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.transaction do
      organization = Organization.singleton
      return unless organization

      ActivityNotification.find_each do |notification|
        notification.organization_id = organization.id
        notification.save!
        Rails.logger.debug '.'
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      organization = Organization.singleton
      return unless organization

      ActivityNotification.find_each do |notification|
        notification.organization_id = nil
        notification.save!
        Rails.logger.debug '.'
      end
    end
  end
end
