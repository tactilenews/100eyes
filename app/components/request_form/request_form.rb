# frozen_string_literal: true

module RequestForm
  class RequestForm < ApplicationComponent
    HINTS = {
      photo: (I18n.t 'request.hints.photo.label'),
      address: (I18n.t 'request.hints.address.label'),
      contact: (I18n.t 'request.hints.contact.label'),
      medicalInfo: (I18n.t 'request.hints.medicalInfo.label'),
      confidential: (I18n.t 'request.hints.confidential.label')
    }.freeze

    def initialize(request:)
      @request = request
    end

    private

    def hints
      HINTS
    end

    def tags
      User.all_tags.map(&:name)
    end

    attr_reader :request
  end
end
