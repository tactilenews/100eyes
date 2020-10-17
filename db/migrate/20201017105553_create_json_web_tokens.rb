# frozen_string_literal: true

class CreateJsonWebTokens < ActiveRecord::Migration[6.0]
  def change
    create_table :json_web_tokens do |t|
      t.string :invalidated_jti

      t.timestamps
    end
  end
end
