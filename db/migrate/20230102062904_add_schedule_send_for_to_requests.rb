# frozen_string_literal: true

class AddScheduleSendForToRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :requests, :schedule_send_for, :datetime, default: nil
  end
end
