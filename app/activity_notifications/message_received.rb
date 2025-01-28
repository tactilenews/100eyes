# frozen_string_literal: true

class MessageReceived < Noticed::Base
  deliver_by :database, format: :to_database, association: :notifications_as_recipient

  param :contributor_id, :message_id, :organization_id

  def to_database
    {
      type: self.class.name,
      contributor_id: params[:contributor_id],
      request_id: params[:request_id],
      message_id: params[:message_id],
      organization_id: params[:organization_id]
    }
  end

  def group_key
    { "#{self.class.to_s.underscore}_request_id".to_sym => record.request_id.presence || record.contributor_id }
  end

  def record_for_avatar
    record.contributor
  end

  def group_message(notifications:)
    if record.request_id.present?
      message_with_request(notifications)
    else
      message_without_request(notifications)
    end
  end

  # rubocop:disable Rails/OutputSafety
  def message_with_request(notifications)
    unique_contributors = notifications.map(&:contributor).uniq
    count = unique_contributors.size

    t(".text_html.#{pluralization_key(count)}",
      contributor_one: unique_contributors.first.name,
      contributor_two: unique_contributors.second&.name,
      request_title: record.request&.title,
      others_count: count - 1).html_safe
  end

  def message_without_request(notifications)
    t('.no_request',
      contributor_name: notifications.first.contributor.name).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    if record.request_id.present?
      organization_request_path(record.request.organization_id, record.request, anchor: "message-#{record.message.id}")
    else
      conversations_organization_contributor_path(record.organization_id, record.contributor_id, anchor: "message-#{record.message.id}")
    end
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
end
