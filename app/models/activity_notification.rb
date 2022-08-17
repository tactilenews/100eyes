# frozen_string_literal: true

class ActivityNotification < ApplicationRecord
  include Noticed::Model
  belongs_to :recipient, polymorphic: true
  store_accessor :params, :request, :contributor

  scope :onboarding_completed, -> { where(type: OnboardingCompleted.name) }
  scope :message_received, -> { where(type: MessageReceived.name) }
  scope :count_per_request, ->(request) { where('params @> ?', Noticed::Coder.dump(request: request).to_json).count }
end
