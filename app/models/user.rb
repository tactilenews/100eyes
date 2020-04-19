# frozen_string_literal: true

class User < ApplicationRecord
  has_many :feedbacks, dependent: :destroy

  def respond_feedback(answer:)
    recent_request = Request.order('created_at').last
    recent_request || return
    Reply.create(user: self, request: recent_request, text: answer)
  end
end
