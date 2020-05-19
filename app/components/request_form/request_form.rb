# frozen_string_literal: true

module RequestForm
  class RequestForm < ApplicationComponent
    HINTS = {
      photo: 'Fotos',
      address: 'Adressen',
      contact: 'Kontaktdaten',
      medicalInfo: 'Medizinische Informationen',
      confidential: 'Vertrauliche Informationen'
    }.freeze

    def initialize(); end

    def hints
      HINTS
    end
  end
end
