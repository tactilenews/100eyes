# frozen_string_literal: true

class AddActiveStateToContributors < ActiveRecord::Migration[6.0]
  def change
    add_column :contributors, :deactivated_at, :datetime, default: nil
  end
end
