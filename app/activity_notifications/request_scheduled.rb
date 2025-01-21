# frozen_string_literal: true

class RequestScheduled < Noticed::Base
  deliver_by :database, format: :to_database, association: :notifications_as_recipient

  param :request_id, :organization_id

  def to_database
    {
      type: self.class.name,
      request_id: params[:request_id],
      organization_id: params[:organization_id]
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
      date: I18n.l(request.schedule_send_for, format: '%A, %-d.%-m.%Y'),
      time: I18n.l(request.schedule_send_for, format: '%H:%M'),
      contributors_count: request.organization.contributors.active.with_tags(request.tag_list).count).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    filter = if record.request.broadcasted_at.present?
               :sent
             else
               :planned
             end
    organization_requests_path(record.request.organization_id, filter: filter, anchor: "request-#{record.request_id}")
  end

  def link_text
    t('.link_text')
  end
end
