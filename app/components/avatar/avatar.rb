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

    def editorial_logo?
      record.is_a?(User) && Setting.onboarding_logo.present?
    end

    def editorial_logo
      Setting.onboarding_logo
    end

    def url
      thumbnail = if record_avatar?
                    record_avatar.variant(resize_to_fit: [200, 200])
                  elsif editorial_logo.image? && editorial_logo.variable?
                    editorial_logo.variant(resize_to_fit: [200, 200])
                  else
                    editorial_logo
                  end
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
