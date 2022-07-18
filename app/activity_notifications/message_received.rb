# frozen_string_literal: true

# To deliver this notification:
#
# MessageReceived.with(contributor: @contributor, request: @request).deliver_later(current_user)
# MessageReceived.with(contributor: @contributor, request: @request).deliver(current_user)

class MessageReceived < Noticed::Base
  # Add your delivery methods
  #
  deliver_by :database
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  # Add required params
  #
  param :contributor, :request

  # Define helper methods to make rendering easier.
  #
  # rubocop:disable Rails/OutputSafety
  def message
    t('.message_html',
      contributor_name: contributor.name,
      request_title: params[:request].title).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    request_path(params[:request].id)
  end

  def link_text
    t('.link_text')
  end

  def contributor
    params[:contributor]
  end
end
