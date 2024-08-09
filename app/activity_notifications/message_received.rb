# frozen_string_literal: true

class MessageReceived < Noticed::Base
  deliver_by :database, format: :to_database, association: :notifications_as_recipient

  param :contributor_id, :request_id, :message_id, :organization_id

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
    { "#{self.class.to_s.underscore}_request_id".to_sym => record.request_id }
  end

  def record_for_avatar
    record.contributor
  end

  # rubocop:disable Rails/OutputSafety
  def group_message(notifications:)
    unique_contributors = notifications.map(&:contributor).uniq
    count = unique_contributors.size

    t(".text_html.#{pluralization_key(count)}",
      contributor_one: unique_contributors.first.name,
      contributor_two: unique_contributors.second&.name,
      request_title: record.request.title,
      others_count: count - 1).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    organization_request_path(record.request.organization_id, record.request, anchor: "message-#{record.message.id}")
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
