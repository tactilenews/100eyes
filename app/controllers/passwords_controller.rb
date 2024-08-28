# frozen_string_literal: true

class PasswordsController < Clearance::PasswordsController
  skip_before_action :require_login, :user_permitted?, :set_organization
end
