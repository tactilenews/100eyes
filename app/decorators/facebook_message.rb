# frozen_string_literal: true

class FacebookMessage
  attr_reader :sender, :text, :message, :photos, :unknown_content

  def initialize(facebook_message)
    @text = facebook_message.text
    # @sender = initialize_user(facebook_message)
    @unknown_content = false
    # @message = initialize_message(facebook_message)
    # @photos = initialize_photos(facebook_message)
  end
end
