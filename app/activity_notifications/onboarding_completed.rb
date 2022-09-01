# frozen_string_literal: true

class OnboardingCompleted < Noticed::Base
  deliver_by :database

  param :contributor

  def group_key
    record
  end

  # rubocop:disable Rails/OutputSafety
  def group_message(notifications:)
    t('.text_html',
      contributor_name: notifications.first.contributor.name,
      contributor_channel: record.channels.first.to_s.capitalize).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def url
    contributor_path(record)
  end

  def link_text
    t('.link_text')
  end

  def record
    params[:contributor]
  end
end
