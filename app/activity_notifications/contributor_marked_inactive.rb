# frozen_string_literal: true

class ContributorMarkedInactive < Noticed::Base
  deliver_by :database, format: :to_database, association: :notifications_as_recipient

  param :contributor_id, :organization_id

  def to_database
    {
      type: self.class.name,
      contributor_id: params[:contributor_id],
      organization_id: params[:organization_id]
    }
  end

  def group_key
    { "#{self.class.to_s.underscore}_contributor_id".to_sym => record.contributor_id }
  end

  def record_for_avatar
    record.contributor
  end

  # rubocop:disable Rails/OutputSafety
  def group_message(notifications:)
    t('.text_html',
      contributor_name: notifications.first.contributor.name,
      contributor_channel: contributor_channel).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    organization_contributor_path(organization_id: record.organization_id, id: record.contributor_id)
  end

  def link_text
    t('.link_text')
  end

  def contributor_channel
    record.contributor.channels.first.to_s.camelize
  end
end
