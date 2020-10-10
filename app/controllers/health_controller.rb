# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :authenticate

  def index
    render json: { status: 'OK' }
  end
end
