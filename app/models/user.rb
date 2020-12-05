# frozen_string_literal: true

class User < ApplicationRecord
  include Clearance::User

  has_one_time_password
  enum otp_module: { enabled: 'enabled', disabled: 'disabled' }, _prefix: true
  validates :password, length: { in: 20..128 }, unless: :skip_password_validation?
end
