# frozen_string_literal: true

class Message::WhatsAppTemplate < ApplicationRecord
  belongs_to :message
end
