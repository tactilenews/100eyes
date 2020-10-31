# frozen_string_literal: true

class DoubleRelationshipBetweenMessagesAndContributors < ActiveRecord::Migration[6.0]
  def change
    change_table :messages do |t|
      t.rename :user_id, :sender_id
      t.belongs_to :user, foreign_key: true
      t.rename :user_id, :recipient_id
    end
  end
end
