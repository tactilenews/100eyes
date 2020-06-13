# frozen_string_literal: true

class AddUnknownContentFlagToMessage < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :unknown_content, :boolean, default: false
  end
end
