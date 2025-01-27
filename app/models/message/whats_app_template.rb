# frozen_string_literal: true

class Message::WhatsAppTemplate < ApplicationRecord
  belongs_to :message

  def read_at=(datetime)
    super

    self.delivered_at = datetime if delivered_at.blank?
  end
end
