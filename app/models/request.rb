# frozen_string_literal: true

class Request < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_many :users, through: :messages
  has_many :photos, through: :messages
  attribute :hints, :string, array: true, default: []
  default_scope { order(created_at: :desc) }

  after_create { Request.broadcast!(self)  }

  delegate :replies, to: :messages

  HINT_TEXTS = {
    photo: (I18n.t 'request.hints.photo.text'),
    address: (I18n.t 'request.hints.address.text'),
    contact: (I18n.t 'request.hints.contact.text'),
    medicalInfo: (I18n.t 'request.hints.medicalInfo.text'),
    confidential: (I18n.t 'request.hints.confidential.text')
  }.freeze

  def plaintext
    parts = []
    parts << 'Hallo, die Redaktion hat eine neue Frage an Sie:'
    parts << text
    parts += hints.map { |hint| HINT_TEXTS[hint.to_sym] }
    parts << 'Vielen Dank für Ihre Hilfe bei unserer Recherche!'
    parts.join("\n\n")
  end

  def stats
    {
      counts: {
        users: messages.map(&:sender_id).compact.uniq.size,
        photos: messages.map { |message| message.photos_count || 0 }.sum,
        replies: messages.count(&:reply?)
      }
    }
  end

  def messages_by_user
    messages.group_by(&:user).transform_values { |messages| messages.sort_by(&:created_at) }
  end

  def self.broadcast!(request)
    User.find_each { |user| Message.create! sender: nil, recipient: user, text: request.plaintext, request: request }
  end
end
