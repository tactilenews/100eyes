class AddThreemaIdToContributors < ActiveRecord::Migration[6.0]
  def change
    add_column :contributors, :threema_id, :string
    add_index :contributors, :threema_id, unique: true
  end
end
