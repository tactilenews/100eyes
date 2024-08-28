# frozen_string_literal: true

class UsersOrganization < ApplicationRecord
  belongs_to :user
  belongs_to :organization
end
