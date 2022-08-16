# frozen_string_literal: true

class ActivityNotification < ApplicationRecord
  include Noticed::Model
  belongs_to :recipient, polymorphic: true
  store_accessor :params, :request
end
