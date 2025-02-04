# frozen_string_literal: true

class ChangeWhatsAppProfileAboutToMessengersDescriptionTextOnOrganizations < ActiveRecord::Migration[6.1]
  def change
    rename_column :organizations, :whats_app_profile_about, :messengers_description_text
  end
end
