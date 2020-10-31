# frozen_string_literal: true

class AttachUsersToActiveRequest < ActiveRecord::Migration[6.0]
  def up
    active_request = Request.reorder(created_at: :desc).first
    return unless active_request

    users_without_active_request = User.find_each.select do |user|
      user.active_request.nil?
    end

    users_without_active_request.each do |user|
      Message.create!(
        recipient: user,
        sender: nil,
        request: active_request,
        text: active_request.plaintext
      )
    end
  end

  def down
    say %(
      I cannot delete the active requests for each user!

      Undoing this migration would mean to delete messages between user
      and request. That is too dangerous, so I rather leave some data behind.
    )
  end
end
