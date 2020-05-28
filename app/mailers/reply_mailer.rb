# frozen_string_literal: true

class ReplyMailer < ApplicationMailer
  def user_not_found_email
    mail(
      to: params[:email],
      subject: 'Wir können Ihre E-Mail Adresse nicht zuordnen',
      body: <<-BODY
        Wir können Ihre E-Mail Adresse #{params[:email]} leider keinem
        unserer Benutzerprofile zuordnen.
      BODY
    )
  end
end
