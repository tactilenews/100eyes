# frozen_string_literal: true

class Request < ApplicationRecord
  include PlaceholderHelper

  has_many :messages, dependent: :destroy
  has_many :contributors, through: :messages
  has_many :photos, through: :messages
  default_scope { order(created_at: :desc) }
  has_noticed_notifications model_name: 'ActivityNotification'

  acts_as_taggable_on :tags

  after_create { Request.broadcast!(self) }

  delegate :replies, to: :messages

  def personalized_text(contributor)
    replace_placeholder(text, 'VORNAME', contributor.first_name.strip)
  end

  def stats
    {
      counts: {
        recipients: messages.map(&:recipient_id).compact.uniq.size,
        contributors: messages.map(&:sender_id).compact.uniq.size,
        photos: messages.map { |message| message.photos_count || 0 }.sum,
        replies: messages.count(&:reply?)
      }
    }
  end

  def messages_by_contributor
    messages
      .where(broadcasted: false)
      .group_by(&:contributor)
      .transform_values { |messages| messages.sort_by(&:created_at) }
  end

  def self.broadcast!(request)
    Contributor.active.with_tags(request.tag_list).each do |contributor|
      Message.create!(
        sender: nil,
        recipient: contributor,
        text: request.personalized_text(contributor),
        request: request,
        broadcasted: true
      )
    end
  end
end
