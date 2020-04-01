class BroadcastController < ApplicationController
  def deliver
    BroadcastMailer.with(subject: params[:subject], text: params[:text]).question_email.deliver_now
  end
end
