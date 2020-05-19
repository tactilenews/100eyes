# frozen_string_literal: true

class Request < ApplicationRecord
  has_many :feedbacks, dependent: :destroy
  attribute :hints, :string, array: true, default: []
  default_scope { order(:created_at) }

  HINT_TEXTS = {
    photo: 'Textbaustein für Foto',
    address: 'Textbaustein für Adressweitergabe',
    contact: 'Textbaustein für Kontaktweitergabe',
    medicalInfo: 'Textbaustein für medizinische Informationen',
    confidential: 'Textbaustein für vertrauliche Informationen'
  }.freeze

  def self.add_reply(answer:, user:)
    recent_request = Request.order('created_at').last
    recent_request || return
    Reply.create(user: user, request: recent_request, text: answer)
  end

  def plaintext
    parts = []
    parts << 'Hallo, die Redaktion hat eine neue Frage an dich:'
    parts << text
    parts += hints.map { |hint| HINT_TEXTS[hint.to_sym] }
    parts << 'Vielen Dank für deine Hilfe bei unserer Recherche!'
    parts.join("\n\n")
  end
end
