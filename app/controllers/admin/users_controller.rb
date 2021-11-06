# frozen_string_literal: true

module Admin
  class UsersController < Admin::ApplicationController
    private

    def resource_params
      params = super
      return params if params.key?(:encrypted_password)

      new_password = SecureRandom.alphanumeric(12)
      params.merge(password: new_password)
    end
  end
end
