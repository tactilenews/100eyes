class QuestionsController < ApplicationController
  def new
  end

  def create
    BroadcastMailer.with(subject: params[:subject], text: params[:text]).question_email.deliver_now
  end
end
