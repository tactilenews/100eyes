# frozen_string_literal: true

class User < ApplicationRecord
  has_many :feedbacks, dependent: :destroy

  def respond_feedback(answer:)
    recent_issue = Issue.order('created_at').last
    recent_issue || return
    Feedback.create(user: self, issue: recent_issue, text: answer)
  end
end
