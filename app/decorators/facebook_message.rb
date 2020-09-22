# frozen_string_literal: true

class FacebookMessage
  attr_reader :sender, :text, :message, :photos, :unknown_content

  def initialize(facebook_message)
    @text = facebook_message.text
    # @sender = initialize_user(facebook_message)
    @message = initialize_message(facebook_message)
    @photos, @unknown_content = initialize_photos_and_unknown_content(facebook_message)
  end

  private

  def initialize_message(_facebook_message)
    Message.new
  end

  def initialize_photos_and_unknown_content(facebook_message)
    return [[], false] unless facebook_message.attachments

    photos = facebook_message.attachments.map do |attachment|
      photo = Photo.new
      remote_file_location = URI(attachment['payload']['url'])
      photo.message = message

      photo.image.attach(io: URI.open(remote_file_location), filename: File.basename(remote_file_location.path))
      photo
    end
    unknown_content = photos.any?(&:invalid?)
    photos = photos.select(&:valid?) # this might not be an image
    [photos, unknown_content]
  end
end
