# frozen_string_literal: true

class Request < ApplicationRecord
  has_many :feedbacks, dependent: :destroy

  def self.add_reply(answer:, user:)
    recent_request = Request.order('created_at').last
    recent_request || return
    Reply.create(user: user, request: recent_request, text: answer)
  end
end
