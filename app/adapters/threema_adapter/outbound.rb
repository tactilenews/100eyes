# frozen_string_literal: true

module ThreemaAdapter
  class Outbound < ApplicationJob
    queue_as :default

    def self.send!(message)
      perform_later(message)
    end

    def perform(message)
      recipient = message.recipient
      return unless recipient&.threema_id

      Threema.new.send(type: :text, threema_id: recipient.threema_id, text: message.text)
    end
  end
end
