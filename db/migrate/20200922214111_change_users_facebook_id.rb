class ChangeUsersFacebookId < ActiveRecord::Migration[6.0]
  def change
    change_column :users, :facebook_id, :bigint
  end
end
