# frozen_string_literal: true

class ReplyMailer < ApplicationMailer
  def user_not_found_email
    mail(
      to: params[:email],
      subject: 'Wir können deine E-Mail Adresse nicht zuordnen',
      body: <<-BODY
        Wir können deine E-Mail Adresse #{params[:email]} leider keinem
        unserer Benutzerprofile zuordnen.
      BODY
    )
  end
end
