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
    text = mail.multipart? ? mail.text_part&.decoded : mail.decoded
    fragment = Loofah.fragment(text)
    plain_text_links = Loofah::Scrubber.new do |node|
      if (node.name == 'a') && node['href']
        href = " (#{node['href']})"
        node.add_child(Nokogiri::XML::Text.new(href, node.document))
      end
    end
    br2lines = Loofah::Scrubber.new do |node|
      node.replace(Nokogiri::XML::Text.new("\n", node.document)) if node.name == 'br'
    end
    result = fragment
             .scrub!(plain_text_links)
             .scrub!(br2lines)
             .scrub!(Loofah::Scrubbers::NewlineBlockElements.new)
             .to_s
    ActionController::Base.helpers.strip_tags(result)
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
