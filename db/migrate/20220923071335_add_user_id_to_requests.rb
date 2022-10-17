# frozen_string_literal: true

class AddUserIdToRequests < ActiveRecord::Migration[6.1]
  def change
    add_reference :requests, :user, foreign_key: true
  end
end
