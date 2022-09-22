# frozen_string_literal: true

class ActivityNotification < ApplicationRecord
  include Noticed::Model
  belongs_to :recipient, polymorphic: true
  belongs_to :contributor, optional: true
  belongs_to :request, optional: true
  belongs_to :message, optional: true
  belongs_to :user, optional: true
end
