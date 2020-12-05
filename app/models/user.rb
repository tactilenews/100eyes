# frozen_string_literal: true

class User < ApplicationRecord
  include Clearance::User

  has_one_time_password

  validates :password, length: { in: 20..128 }, unless: :skip_password_validation?
end
