# frozen_string_literal: true

class AddRecordIdsToActivityNotifications < ActiveRecord::Migration[6.1]
  def change
    add_reference :activity_notifications, :contributor, foreign_key: true
    add_reference :activity_notifications, :message, foreign_key: true
    add_reference :activity_notifications, :request, foreign_key: true
    add_reference :activity_notifications, :user, foreign_key: true
  end
end
