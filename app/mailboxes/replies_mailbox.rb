# frozen_string_literal: true

class RepliesMailbox < ApplicationMailbox
  before_processing :ensure_sender_is_a_user

  def process
    user.reply(EmailMessage.new(mail))
  end

  private

  def ensure_sender_is_a_user
    bounce_with Mailer.with(email: mail.from.first).user_not_found_email unless user
  end

  def user
    @user ||= User.find_by_email(mail.from)
  end
end
