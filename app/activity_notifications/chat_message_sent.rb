# frozen_string_literal: true

# To deliver this notification:
#
# ChatMessageSent.with(contributor: @contributor, request: @request, editor: @editor, message: @message).deliver_later(current_user)
# ChatMessageSent.with(contributor: @contributor, request: @request, editor: @editor, message: @message).deliver(current_user)

class ChatMessageSent < Noticed::Base
  # Add your delivery methods
  #
  deliver_by :database
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  # Add required params
  #
  param :contributor, :request, :editor, :message

  # Define helper methods to make rendering easier.
  #
  # rubocop:disable Rails/OutputSafety
  def text
    t('.text_html',
      contributor_name: contributor.name,
      request_title: request.title,
      editor_name: editor.name).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    message.chat_message_link
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

  def editor
    params[:editor]
  end

  def message
    params[:message]
  end
end
