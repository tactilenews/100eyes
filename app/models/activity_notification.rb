# frozen_string_literal: true

class ActivityNotification < ApplicationRecord
  include Noticed::Model
  belongs_to :recipient, polymorphic: true
  store_accessor :params, :request, :contributor, :user

  scope :onboarding_completed, -> { where(type: OnboardingCompleted.name) }
  scope :message_received, -> { where(type: MessageReceived.name) }
  scope :chat_message_sent, -> { where(type: ChatMessageSent.name) }

  def self.count_per_request(request, user = nil, contributor = nil)
    query = where('params @> ?', Noticed::Coder.dump(request: request).to_json)
    query = query.where('params @> ?', Noticed::Coder.dump(user: user).to_json) if user.present?
    if contributor.present?
      with_contributor = query.where('params @> ?', Noticed::Coder.dump(contributor: contributor).to_json)
      query.count - with_contributor.count
    else
      query.count
    end
  end
end
