# frozen_string_literal: true

class User < ApplicationRecord
  include Clearance::User

  has_many :activity_notifications, as: :recipient

  has_one_time_password
  validates :password, length: { in: 8..128 }, unless: :skip_password_validation?

  def name
    "#{first_name} #{last_name}"
  end
end
