class AddHighlightedFlagToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :highlighted, :boolean, default: false
  end
end
