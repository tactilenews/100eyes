# frozen_string_literal: true

class MessageReceived < Noticed::Base
  deliver_by :database

  param :contributor, :request, :message

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
