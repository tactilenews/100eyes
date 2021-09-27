# frozen_string_literal: true

class ChangeContributorPhoneNumberColumnName < ActiveRecord::Migration[6.1]
  def change
    rename_column :contributors, :phone_number, :signal_phone_number
  end
end
