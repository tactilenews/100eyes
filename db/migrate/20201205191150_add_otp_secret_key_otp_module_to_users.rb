# frozen_string_literal: true

class AddOtpSecretKeyOtpModuleToUsers < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL.squish
      CREATE TYPE user_otp_module AS ENUM ('enabled', 'disabled');
    SQL

    change_table :users, bulk: true do |t|
      t.string :otp_secret_key
      t.column :otp_module, :user_otp_module, default: 'disabled'
    end
  end

  def down
    change_table :users, bulk: true do |t|
      t.remove :otp_secret_key
      t.remove :otp_module, default: 'disabled'
    end

    execute <<-SQL.squish
      DROP TYPE user_otp_module;
    SQL
  end
end
