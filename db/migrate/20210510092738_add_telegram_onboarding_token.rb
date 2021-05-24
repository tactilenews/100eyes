# frozen_string_literal: true

class AddTelegramOnboardingToken < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :telegram_onboarding_token, :string, unique: true
  end
end
