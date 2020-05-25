# frozen_string_literal: true

class Request < ApplicationRecord
  has_many :replies, dependent: :destroy
  attribute :hints, :string, array: true, default: []
  default_scope { order(created_at: :desc) }

  def self.active_request
    order(created_at: :desc).first
  end

  HINT_TEXTS = {
    photo: 'Textbaustein für Foto',
    address: 'Textbaustein für Adressweitergabe',
    contact: 'Textbaustein für Kontaktweitergabe',
    medicalInfo: 'Textbaustein für medizinische Informationen',
    confidential: 'Textbaustein für vertrauliche Informationen'
  }.freeze

  def plaintext
    parts = []
    parts << 'Hallo, die Redaktion hat eine neue Frage an dich:'
    parts << text
    parts += hints.map { |hint| HINT_TEXTS[hint.to_sym] }
    parts << 'Vielen Dank für deine Hilfe bei unserer Recherche!'
    parts.join("\n\n")
  end
end
