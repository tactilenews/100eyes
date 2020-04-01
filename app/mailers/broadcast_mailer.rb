class BroadcastMailer < ApplicationMailer
  def question_email
    @text = params[:text]
    mail(to: 'somebody@example.org', subject: params[:subject])
  end
end
