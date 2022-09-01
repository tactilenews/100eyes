# frozen_string_literal: true

class OnboardingCompleted < Noticed::Base
  deliver_by :database, format: :to_database, association: :activity_notifications

  param :contributor_id

  def to_database
    {
      type: self.class.name,
      contributor_id: params[:contributor_id]
    }
  end

  def group_key
    record.contributor_id
  end

  def record_for_avatar
    record.contributor
  end

  # rubocop:disable Rails/OutputSafety
  def group_message(notifications:)
    t('.text_html',
      contributor_name: notifications.first.contributor.name,
      contributor_channel: record.contributor.channels.first.to_s.capitalize).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    contributor_path(record.contributor_id)
  end

  def link_text
    t('.link_text')
  end
end
