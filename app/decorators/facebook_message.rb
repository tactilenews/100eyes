# frozen_string_literal: true

class FacebookMessage
  attr_reader :sender, :text, :message, :photos, :unknown_content

  def initialize(facebook_message)
    @text = facebook_message.text
    @sender = initialize_user(facebook_message)
    @message = initialize_message(facebook_message)
    @photos, @unknown_content = initialize_photos_and_unknown_content(facebook_message)
  end

  private

  def initialize_user(facebook_message)
    facebook_id = facebook_message.sender['id'].to_i
    sender = User.find_by(facebook_id: facebook_id)
    sender ||= User.new(facebook_id: facebook_id)
    sender
  end

  def initialize_message(facebook_message)
    message_id = facebook_message.id
    message = Message.new(text: text, sender: sender, facebook_message_id: message_id)
    message.raw_data.attach(
      io: StringIO.new(JSON.generate(facebook_message.messaging)),
      filename: 'facebook_api.json',
      content_type: 'application/json'
    )
    message
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
    message.unknown_content = unknown_content
    photos = photos.select(&:valid?) # this might not be an image
    [photos, unknown_content]
  end
end
