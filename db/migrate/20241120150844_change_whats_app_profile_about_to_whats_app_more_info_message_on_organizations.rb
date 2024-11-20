# frozen_string_literal: true

class ChangeWhatsAppProfileAboutToWhatsAppMoreInfoMessageOnOrganizations < ActiveRecord::Migration[6.1]
  def change
    rename_column :organizations, :whats_app_profile_about, :whats_app_more_info_message
  end
end
