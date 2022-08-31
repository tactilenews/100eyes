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

  param :contributor, :request, :message

  # Define helper methods to make rendering easier.
  #
  def group_key
    request
  end

  # rubocop:disable Rails/OutputSafety
  def group_message(notifications:)
    unique_contributors = notifications.map(&:contributor).uniq
    count = unique_contributors.size

    t(".text_html.#{pluralization_key(count)}",
      contributor_one: unique_contributors.first.name,
      contributor_two: unique_contributors.second&.name,
      request_title: request.title,
      others_count: count - 1).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    request_path(request, anchor: "message-#{message.id}")
  end

  def link_text
    t('.link_text')
  end

  def record
    params[:contributor]
  end

  def request
    params[:request]
  end

  def message
    params[:message]
  end

  def pluralization_key(count)
    case count
    when 1
      :one
    when 2
      :two
    else
      :other
    end
  end
end
