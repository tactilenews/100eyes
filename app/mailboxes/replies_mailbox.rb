# frozen_string_literal: true

class RepliesMailbox < ApplicationMailbox
  before_processing :ensure_sender_is_a_user

  def process
    Request.add_reply(user: user, answer: mail.decoded)
  end

  private

  def ensure_sender_is_a_user
    bounce_with ReplyMailer.with(email: mail.from.first).user_not_found_email unless user
  end

  def user
    @user ||= User.find_by(email: mail.from)
  end
end
