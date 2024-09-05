# frozen_string_literal: true

class RemoveGlobalEnvVariablesFromOrganizations < ActiveRecord::Migration[6.1]
  def change
    change_table :organizations, bulk: true do |t|
      t.remove :three_sixty_dialog_partner_id, type: :string
      t.remove :three_sixty_dialog_partner_username, type: :string
      t.remove :encrypted_three_sixty_dialog_partner_password, type: :string
      t.remove :encrypted_three_sixty_dialog_partner_password_iv, type: :string
    end
  end
end
