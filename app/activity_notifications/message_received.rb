# frozen_string_literal: true

# To deliver this notification:
#
# MessageReceived.with(contributor: @contributor, request: @request, message: @message).deliver_later(current_user)
# MessageReceived.with(contributor: @contributor, request: @request, message: @message).deliver(current_user)

class MessageReceived < Noticed::Base
  # Add your delivery methods
  #
  deliver_by :database
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  # Add required params
  #
  param :contributor, :request, :message

  # Define helper methods to make rendering easier.
  #
  # rubocop:disable Rails/OutputSafety
  def text
    t('.text_html',
      contributor_name: contributor.name,
      request_title: request.title).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    request_path(request, anchor: "message-#{message.id}")
  end

  def link_text
    t('.link_text')
  end

  def contributor
    params[:contributor]
  end

  def request
    params[:request]
  end

  def message
    params[:message]
  end
end
