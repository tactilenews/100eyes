# frozen_string_literal: true

class AddOtpSecretKeyOtpModuleToUsers < ActiveRecord::Migration[6.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :otp_secret_key
      t.column :otp_enabled, :boolean, default: false
    end
  end
end
