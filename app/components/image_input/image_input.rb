# frozen_string_literal: true

module ImageInput
  class ImageInput < ApplicationComponent
    def initialize(id: nil, value: nil, **)
      super

      @id = id
      @value = value
    end

    private

    attr_reader :id, :value

    def url
      url_for(blob) if blob?
    end

    def filename
      blob.filename if blob?
    end

    def thumbnail
      if blob? && blob.variable?
        blob.variant(resize_to_fit: [200, 200])
      elsif blob?
        blob
      end
    end

    def thumbnail?
      thumbnail.present?
    end

    def thumbnail_url
      url_for(thumbnail) if thumbnail?
    end

    def blob
      value&.blob
    end

    def blob?
      blob.present? && blob.instance_of?(ActiveStorage::Blob) && blob.image?
    end
  end
end
