# frozen_string_literal: true

class RepliesMailbox < ApplicationMailbox
  before_processing :ensure_sender_is_a_contributor

  def process
    contributor.reply(EmailMessage.new(mail))
  end

  private

  def ensure_sender_is_a_contributor
    bounce_with Mailer.with(email: mail.from.first).contributor_not_found_email unless contributor
  end

  def contributor
    @contributor ||= Contributor.with_lowercased_email(mail.from)
  end
end
