# frozen_string_literal: true

module Avatar
  class Avatar < ApplicationComponent
    delegate :avatar, :avatar?, to: :record, prefix: true

    def initialize(record: nil, expandable: false, **)
      super
      @record = record
      @expandable = expandable
    end

    private

    attr_reader :record

    def key
      record&.id
    end

    def url
      thumbnail = record_avatar.variant(resize_to_fit: [200, 200])
      url_for(thumbnail)
    end

    def initials
      return '?' unless record

      initials = record.name.split.map { |part| part&.first }

      return '?' if initials.empty?

      initials.join
    end

    def expandable?
      @expandable
    end
  end
end
