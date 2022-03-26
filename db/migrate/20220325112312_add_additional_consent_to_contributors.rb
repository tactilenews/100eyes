# frozen_string_literal: true

class AddAdditionalConsentToContributors < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :additional_consent_given_at, :datetime
  end
end
