# frozen_string_literal: true

class DropNotNullConstraintOnMessageUserIdForeignKey < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:messages, :user_id, true)
  end
end
