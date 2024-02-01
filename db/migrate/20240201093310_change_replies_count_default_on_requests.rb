class ChangeRepliesCountDefaultOnRequests < ActiveRecord::Migration[6.1]
  def up
    change_column :requests, :replies_count, :integer, default: 0
  end

  def down
    change_column :requests, :replies_count, :integer, default: nil
  end
end
