# frozen_string_literal: true

class AddCreatorToMessage < ActiveRecord::Migration[6.0]
  def change
    add_reference :messages, :creator, references: :users
  end
end
