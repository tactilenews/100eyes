# frozen_string_literal: true

class EmailMessage
  attr_reader :sender, :text, :message, :photos

  def initialize(mail)
    @text = initialize_text(mail)
    @sender = initialize_user(mail)
    @message = initialize_message(mail)
    @photos = initialize_photos(mail)
  end

  private

  def initialize_text(mail)
    return mail.decoded unless  mail.multipart?

    mail.text_part&.decoded
  end

  def initialize_user(mail)
    User.find_by(email: mail.from)
  end

  def initialize_message(_mail)
    Message.new(text: text, sender: sender)
  end

  def initialize_photos(mail)
    photos = mail.attachments.map do |attachment|
      photo = Photo.new
      photo.message = message
      photo.image.attach(io: StringIO.new(attachment.decoded), filename: attachment.filename)
      photo
    end
    photos.select(&:valid?) # this might not be an image
  end
end
