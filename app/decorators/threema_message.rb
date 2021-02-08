# frozen_string_literal: true

class ThreemaMessage
  attr_reader :sender, :message

  def initialize(threema_message)
    threema_decrypted = Threema.new.receive(payload: threema_message)
    @sender = Contributor.find_by(threema_id: threema_message[:from])
    return unless @sender

    @message = initialize_message(threema_decrypted)
  end

  private

  def initialize_message(threema_decrypted)
    message = Message.new(text: threema_decrypted.content, sender: sender)
    message.raw_data.attach(
      io: StringIO.new(JSON.generate(threema_decrypted)),
      filename: 'threema_api.json',
      content_type: 'application/json'
    )
    message
  end
end
