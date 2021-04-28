# frozen_string_literal: true

class AddDataProcessingConsentToContributors < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :data_processing_consented_at, :datetime, default: nil
  end
end
