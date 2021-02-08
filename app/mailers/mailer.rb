# frozen_string_literal: true

class Mailer < ApplicationMailer
  default template_name: :mailer
  default from: -> { default_from }

  before_action do
    @text = params[:text]
    headers(params[:headers])
    mail(params[:mail])
  end

  def new_message_email; end

  def contributor_not_found_email; end

  private

  def default_from
    "#{Setting.project_name} <#{Setting.email_from_address}>"
  end
end
