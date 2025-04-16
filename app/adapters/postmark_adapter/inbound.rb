# frozen_string_literal: true

module PostmarkAdapter
  class Inbound
    attr_reader :sender, :text, :organization, :message, :photos, :unknown_content, :file

    def self.bounce!(mail, organization)
      mailer_params = {
        organization: organization,
        text: I18n.t('adapter.postmark.contributor_not_found_email.text'),
        mail: {
          subject: I18n.t('adapter.postmark.contributor_not_found_email.subject'),
          message_stream: ENV.fetch('POSTMARK_TRANSACTIONAL_STREAM', 'outbound'),
          to: mail.from.first
        }
      }
      PostmarkAdapter::Outbound.with(mailer_params).bounce_email
    end

    def self.from(raw_data)
      new(Mail.new(raw_data.download))
    end

    def initialize(mail)
      @file = nil
      @text = initialize_text(mail)
      @organization = initialize_organization(mail)
      @sender = initialize_contributor(mail)
      @message = initialize_message(mail)
      @photos, @unknown_content = initialize_photos_and_unknown_content(mail)
      @message.unknown_content = unknown_content
      @photos.each do |photo|
        @message.association(:files).add_to_target(photo)
      end
    end

    private

    def initialize_text(mail)
      text = mail.multipart? ? mail.html_part&.decoded : mail.decoded
      fragment = Loofah.fragment(text)
      scrubbed = scrubbers.reduce(fragment) { |result, scrubber| result.scrub!(scrubber) }
      ActionController::Base.helpers.strip_tags(scrubbed.to_s)
    end

    def initialize_organization(mail)
      Organization.find_by(email_from_address: mail.to)
    end

    def initialize_contributor(mail)
      organization.contributors.with_lowercased_email(mail.from)
    end

    def initialize_message(mail)
      message = Message.new(text: text, sender: sender, organization: organization)
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
        photo = Message::File.new
        photo.message = message
        photo.attachment.attach(io: StringIO.new(attachment.decoded), filename: attachment.filename)
        photo
      end
      photos, unknown_files = photos.partition(&:image_attachment?)
      unknown_content = unknown_files.present?
      [photos, unknown_content]
    end

    def scrubbers
      plain_text_links = Loofah::Scrubber.new do |node|
        if (node.name == 'a') && node['href']
          href = " (#{node['href']})"
          node.add_child(Nokogiri::XML::Text.new(href, node.document))
        end
      end
      br2lines = Loofah::Scrubber.new do |node|
        node.replace(Nokogiri::XML::Text.new("\n", node.document)) if node.name == 'br'
      end
      rm_previous_message = Loofah::Scrubber.new do |node|
        node.remove if [node['class'], node['id']].map(&:to_s).any? { |v| v.include? 'hundred-eyes-message' }
      end
      [rm_previous_message, plain_text_links, br2lines, Loofah::Scrubbers::NewlineBlockElements.new]
    end
  end
end
