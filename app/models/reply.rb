# frozen_string_literal: true

class Reply < ApplicationRecord
  include PgSearch::Model

  default_scope { order(created_at: :desc) }

  multisearchable against: :text

  belongs_to :user
  belongs_to :request
  has_many :photos, dependent: :destroy

  def self.from_telegram_message(message)
    request = Request.active_request or return nil
    user = User.upsert_via_telegram(message)
    media_group_id = message['media_group_id']
    text = message['text'] || message['caption']
    ActiveRecord::Base.transaction do
      reply = Reply.find_by(telegram_media_group_id: media_group_id) if media_group_id
      reply ||= create!(text: text, user: user, request: request, telegram_media_group_id: media_group_id)
      reply.photos << Photo.create(telegram_message: message, reply: reply)
    end
  end
end
