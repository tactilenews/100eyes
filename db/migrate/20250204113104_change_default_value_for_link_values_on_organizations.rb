# frozen_string_literal: true

class ChangeDefaultValueForLinkValuesOnOrganizations < ActiveRecord::Migration[6.1]
  # rubocop:disable Rails/BulkChangeTable
  def change
    change_column_default :organizations, :onboarding_data_protection_link, from: 'https://tactile.news/100eyes-datenschutz/', to: nil
    change_column_default :organizations, :onboarding_imprint_link, from: 'https://tactile.news/impressum/', to: nil
  end
  # rubocop:enable Rails/BulkChangeTable
end
