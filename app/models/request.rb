# frozen_string_literal: true

class Request < ApplicationRecord
  has_many :replies, dependent: :destroy
  has_many :users, through: :replies
  has_many :photos, through: :replies
  attribute :hints, :string, array: true, default: []
  default_scope { order(created_at: :desc) }

  def self.active_request
    reorder(created_at: :desc).first
  end

  HINT_TEXTS = {
    photo: 'Schicken Sie uns doch auch ein Foto (oder mehrere). Bitte schicken Sie nur Fotos, die Sie selber gemacht haben. Mit der Zusendung von Fotos geben Sie gleichzeitig Ihr Einverständnis für eine mögliche Veröffentlichung. Bei Veröffentlichung nennen wir Sie als Urheber (Foto: Max Mustermann/100eyes).',
    address: 'Schicken Sie uns doch eine Adresse oder genaue Koordinaten. Wir nutzen die Geodaten für unsere Recherchen und werden sie eventuell in einem Text verarbeiten oder als Datenpunkt auf einer Karte verwenden.',
    contact: 'Schicken Sie uns gerne Kontaktdaten. Wir nutzen die Kontaktdaten für unsere Recherchen und werden die Person eventuell kontaktieren, aber keine Kontaktdaten veröffentlichen.',
    medicalInfo: 'Sie stellen uns hier möglicherweise sensible medizinische Informationen bereit. Wir sind uns dessen bewusst und behandeln Ihre Daten mit aller gebotenen Vorsicht. Wenn Sie uns Daten schicken, helfen uns diese Informationen für unsere weiteren Recherchen. Ihre Daten werden wir nur intern auswerten, aber nicht veröffentlichen. Es sei denn, Sie geben Ihr ausdrückliches Einverständnis, nachdem wir Sie separat darum gebeten haben.',
    confidential: 'Sie stellen uns hier möglicherweise vertrauliche Informationen bereit. Wir sind uns dessen bewusst und behandeln diese Informationen mit aller gebotenen Vorsicht. Wir werden Ihre Informationen nur intern auswerten, aber nicht ungefragt veröffentlichen.'
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
        users: replies.map(&:user_id).uniq.size,
        photos: replies.map { |reply| reply.photos_count || 0 }.sum,
        replies: replies.size
      }
    }
  end
end
