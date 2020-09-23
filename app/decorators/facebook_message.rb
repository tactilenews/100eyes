# frozen_string_literal: true

class FacebookMessage
  UNKNOWN_CONTENT_TYPES = %w[ audio video file template ].freeze
  attr_reader :sender, :text, :message, :photos, :unknown_content

  def initialize(facebook_message)
    @text = facebook_message.text
    @sender = initialize_user(facebook_message)
    @message = initialize_message(facebook_message)
    # @photos = initialize_photos(facebook_message)
  end


  def initialize_user(facebook_message)
    facebook_id = facebook_message.sender['id'].to_i
    sender = User.find_by(facebook_id: facebook_id)
    sender ||= User.new(facebook_id: facebook_id)
    sender
  end

  def initialize_message(facebook_message)
    message_id = facebook_message.id
    message = Message.find_by(facebook_message_id: message_id) if message_id
    message ||= Message.new(text: text, sender: sender, facebook_message_id: message_id)
    message.unknown_content = unknown_content
    message
  end

end

