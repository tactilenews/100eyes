# frozen_string_literal: true

class AddOrganizationIdToActivityNotifications < ActiveRecord::Migration[6.1]
  def change
    add_reference :activity_notifications, :organization, foreign_key: true
  end
end
