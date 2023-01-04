# frozen_string_literal: true

class RequestScheduled < Noticed::Base
  deliver_by :database, format: :to_database, association: :notifications_as_recipient

  param :request_id

  def to_database
    {
      type: self.class.name,
      request_id: params[:request_id]
    }
  end

  def group_key
    { "#{self.class.to_s.underscore}_request_id".to_sym => record.request_id }
  end

  def record_for_avatar
    record.user
  end

  # rubocop:disable Rails/OutputSafety
  def group_message(notifications:)
    request = notifications.first.request
    t('.text_html',
      request_title: request.title,
      date: request.schedule_send_for.strftime('%A, %-d.%-m.%Y'),
      time: request.schedule_send_for.strftime('%H:%M'),
      contributors_count: Contributor.active.with_tags(request.tag_list).count).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    request_path(record.request)
  end

  def link_text
    t('.link_text')
  end
end
