class AddUnsubscribedAtToContributors < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :unsubscribed_at, :datetime, default: nil
  end
end
