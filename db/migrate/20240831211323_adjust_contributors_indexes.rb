# frozen_string_literal: true

class AdjustContributorsIndexes < ActiveRecord::Migration[6.1]
  def change
    remove_index :contributors, :email
    remove_index :contributors, :signal_phone_number
    remove_index :contributors, :telegram_chat_id
    remove_index :contributors, :telegram_id
    remove_index :contributors, :threema_id
    remove_index :contributors, :whats_app_phone_number
    add_index :contributors, %i[organization_id email], unique: true, name: 'idx_org_email'
    add_index :contributors, %i[organization_id signal_phone_number], unique: true, name: 'idx_org_signal_phone_number'
    add_index :contributors, %i[organization_id telegram_chat_id], unique: true, name: 'idx_org_telegram_chat_id'
    add_index :contributors, %i[organization_id telegram_id], unique: true, name: 'idx_org_telegram_id'
    add_index :contributors, %i[organization_id threema_id], unique: true, name: 'idx_org_threema_id'
    add_index :contributors, %i[organization_id whats_app_phone_number], unique: true, name: 'idx_org_whats_app_phone_number'
  end
end
