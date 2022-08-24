# frozen_string_literal: true

class ActivityNotification < ApplicationRecord
  include Noticed::Model
  belongs_to :recipient, polymorphic: true
  store_accessor :params, :request, :contributor, :user

  scope :onboarding_completed, -> { where(type: OnboardingCompleted.name) }
  scope :message_received, -> { where(type: MessageReceived.name) }
  scope :chat_message_sent, -> { where(type: ChatMessageSent.name) }
end
