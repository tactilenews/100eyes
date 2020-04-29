# frozen_string_literal: true

class User < ApplicationRecord
  has_many :replies, dependent: :destroy

  def name
    "#{first_name} #{last_name}"
  end

  def name=(full_name)
    first_name, last_name = full_name.split(' ')
    self.first_name = first_name
    self.last_name = last_name
  end
end
