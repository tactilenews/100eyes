# frozen_string_literal: true

class MessageGenerator
  def self.generate_message(params:, raw_data:)
    message = Message.new(params)
    message.raw_data.attach(raw_data)
    message
  end
end
