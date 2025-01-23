# frozen_string_literal: true

class ChangeRequestIdNullableOnMessages < ActiveRecord::Migration[6.1]
  def change
    change_column_null :messages, :request_id, true
  end
end
