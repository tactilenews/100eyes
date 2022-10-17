# frozen_string_literal: true

class MakeSenderOnMessagePolymorphic < ActiveRecord::Migration[6.1]
  def up
    change_table :messages, bulk: true do |t|
      t.remove_index :sender_id
      t.change :sender_id, :bigint
      t.string :sender_type
      t.index %i[sender_id sender_type]
    end
    remove_foreign_key :messages, column: :sender_id
  end

  def down
    change_table :messages, bulk: true do |t|
      t.remove_index %i[sender_id sender_type]
      t.change :sender_id, :integer
      t.remove :sender_type
      t.index :sender_id
    end
    add_foreign_key :messages, :contributors, column: :sender_id
  end
end
