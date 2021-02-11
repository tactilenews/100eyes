# frozen_string_literal: true

module ThreemaAdapter
  class Outbound
    attr_reader :message

    delegate :recipient, to: :message

    def initialize(message:)
      @message = message
    end

    def send!
      return unless recipient&.threema_id

      Threema.new.send(type: :text, threema_id: recipient.threema_id, text: message.text)
    end
  end
end
