# frozen_string_literal: true

class DropNotNullConstraintOnMessageUserIdForeignKey < ActiveRecord::Migration[6.0]
  def change
    change_column :messages, :user_id, :integer, null: true
  end
end
