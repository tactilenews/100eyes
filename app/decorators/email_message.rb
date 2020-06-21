# frozen_string_literal: true

class EmailMessage
  attr_reader :sender, :text, :message, :photos, :unknown_content

  def self.from(raw_data)
    new(Mail.new(raw_data.download))
  end

  def initialize(mail)
    @text = initialize_text(mail)
    @sender = initialize_user(mail)
    @message = initialize_message(mail)
    @photos, @unknown_content = initialize_photos_and_unknown_content(mail)
    @message.unknown_content = unknown_content
  end

  private

  def initialize_text(mail)
    return mail.decoded unless mail.multipart?

    mail.text_part&.decoded
  end

  def initialize_user(mail)
    User.find_by_email(mail.from)
  end

  def initialize_message(mail)
    message = Message.new(text: text, sender: sender)
    message.raw_data.attach(
      io: StringIO.new(mail.encoded),
      filename: 'email.eml',
      content_type: 'message/rfc822'
    )
    message.unknown_content = unknown_content
    message
  end

  def initialize_photos_and_unknown_content(mail)
    photos = mail.attachments.map do |attachment|
      photo = Photo.new
      photo.message = message
      photo.image.attach(io: StringIO.new(attachment.decoded), filename: attachment.filename)
      photo
    end
    unknown_content = photos.any?(&:invalid?)
    photos = photos.select(&:valid?) # this might not be an image
    [photos, unknown_content]
  end
end
