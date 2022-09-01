# frozen_string_literal: true

class ChatMessageSent < Noticed::Base
  deliver_by :database

  param :contributor, :request, :user, :message

  def group_key
    [request, user]
  end

  # rubocop:disable Rails/OutputSafety
  def group_message(notifications:)
    unique_contributors = notifications.map(&:contributor).uniq
    count = unique_contributors.size

    t(group_message_key(notifications.first.recipient_id, count),
      contributor_one: unique_contributors.first.name,
      contributor_two: unique_contributors.second&.name,
      request_title: request.title,
      user_name: user.name,
      count: count,
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

  def user
    params[:user]
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

  def group_message_key(current_user_id, count)
    ".#{user.id == current_user_id ? 'my_' : ''}text_html.#{pluralization_key(count)}"
  end
end
