class AddFacebookMessageIdToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :facebook_message_id, :string
  end
end
