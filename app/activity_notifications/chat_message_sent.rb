# frozen_string_literal: true

class ChatMessageSent < Noticed::Base
  deliver_by :database, format: :to_database, association: :activity_notifications

  param :contributor_id, :request_id, :user_id, :message_id

  def to_database
    {
      type: self.class.name,
      contributor_id: params[:contributor_id],
      request_id: params[:request_id],
      user_id: params[:user_id],
      message_id: params[:message_id]
    }
  end

  def group_key
    [record.request_id, record.user_id]
  end

  def record_for_avatar
    record.user
  end

  # rubocop:disable Rails/OutputSafety
  def group_message(notifications:)
    unique_contributors = notifications.map(&:contributor).uniq
    count = unique_contributors.size

    t(group_message_key(notifications.first.recipient_id, count),
      contributor_one: unique_contributors.first.name,
      contributor_two: unique_contributors.second&.name,
      request_title: record.request.title,
      user_name: record.user.name,
      count: count,
      others_count: count - 1).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    request_path(record.request, anchor: "message-#{record.message.id}")
  end

  def link_text
    t('.link_text')
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
    ".#{record.user_id == current_user_id ? 'my_' : ''}text_html.#{pluralization_key(count)}"
  end
end