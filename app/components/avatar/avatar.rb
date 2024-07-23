# frozen_string_literal: true

module Avatar
  class Avatar < ApplicationComponent
    delegate :avatar, :avatar?, to: :record, prefix: true

    def initialize(organization:, record: nil, expandable: false, **)
      super

      @organization = organization
      @record = record || User.new
      @expandable = expandable
    end

    private

    attr_reader :record, :organization

    def key
      record&.id
    end

    def editorial_logo?
      record.is_a?(User) && organization.channel_image.attached?
    end

    def editorial_logo
      organization.channel_image
    end

    def url
      thumbnail = if record_avatar?
                    record_avatar.variant(resize_to_fit: [200, 200])
                  else
                    editorial_logo.variant(resize_to_fit: [200, 200])
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
